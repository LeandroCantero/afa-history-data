require 'date'
require 'logutils'

# Load the legacy sportdb parser first because sportdb-quick owns the value
# converter. Remove its deprecated top-level compatibility constant before
# loading the modern parser, then pin that constant to the modern parser.
require 'sportdb/quick'
Object.send(:remove_const, :RaccMatchParser) if Object.const_defined?(:RaccMatchParser, false)
require 'fbtxt/parser'
require 'sportdb/structs'

expected_gems = {
  'fbtok' => '0.9.1',
  'fbtxt-parser' => '0.9.1',
  'fbtxt-document' => '0.9.1',
  'sportdb-quick' => '0.8.0',
  'sportdb-models_v2' => '0.0.1',
  'fbtxt2sqlite' => '0.0.1'
}.freeze

expected_gems.each do |name, expected|
  actual = Gem::Specification.find_by_name(name).version.to_s
  raise LoadError, "COMPAT_VERSION_MISMATCH: #{name} #{actual}; expected #{expected}" unless actual == expected
end

unless Object.const_defined?(:RaccMatchParser, false) && RaccMatchParser.equal?(Fbtxt::Parser)
  raise LoadError, 'COMPAT_LOAD_ORDER: RaccMatchParser is not pinned to Fbtxt::Parser 0.9.1'
end

module SportDb
  Logging = LogUtils::Logging unless const_defined?(:Logging, false)

  class CompatibilityError < StandardError; end

  class MatchParser
    class << self
      attr_accessor :debug

      def parse(lines, start:)
        new(lines, start).parse
      end
    end

    attr_reader :errors

    def initialize(lines_or_text, start_date)
      @text = lines_or_text.is_a?(Array) ? lines_or_text.join("\n") : lines_or_text.to_s
      @text = "#{@text}\n" unless @text.end_with?("\n")
      @start_date = start_date
      @errors = []
    end

    def errors?
      !@errors.empty?
    end

    def parse
      if @text.match?(/\(\s*agg\b/i)
        raise CompatibilityError, 'COMPAT_UNSUPPORTED_AGG: aggregate scores have no models_v2 database field'
      end

      result = Fbtxt.parse(@text)
      reject_parser_errors!(result.errors)
      validate_tree!(result.tree)
      contexts = structural_contexts(result.tree)

      converter = SportDb::MatchTree.new(result.tree, start: @start_date)
      teams, modern_matches, rounds, groups = converter.convert
      reject_converter_errors!(converter.errors)

      unless contexts.length == modern_matches.length
        raise CompatibilityError, 'COMPAT_CONVERTER_ERROR: match count differs from the modern parse tree'
      end

      matches = modern_matches.zip(contexts).map { |match, context| build_legacy_match(match, context) }
      [teams, matches, rounds, groups]
    rescue CompatibilityError => error
      @errors << error.message unless @errors.include?(error.message)
      raise
    rescue SystemExit => error
      message = "COMPAT_CONVERTER_ABORT: modern converter attempted exit #{error.status}"
      @errors << message
      raise CompatibilityError, message
    rescue StandardError => error
      message = "COMPAT_PARSER_ERROR: #{error.class}: #{error.message}"
      @errors << message
      raise CompatibilityError, message
    end

    private

    ALLOWED_NODES = [
      Fbtxt::Parser::BlankLine,
      Fbtxt::Parser::NoteLine,
      Fbtxt::Parser::GroupDef,
      Fbtxt::Parser::RoundOutline,
      Fbtxt::Parser::DateHeader,
      Fbtxt::Parser::MatchLine
    ].freeze

    def reject_parser_errors!(errors)
      return if errors.empty?

      details = errors.map(&:to_s).join(' | ')
      raise CompatibilityError, "COMPAT_PARSER_ERROR: #{details}"
    end

    def validate_tree!(tree)
      tree.each do |node|
        if node.is_a?(Fbtxt::Parser::MatchLineBye)
          raise CompatibilityError, 'COMPAT_UNSUPPORTED_BYE: bye records have no two-team database representation'
        end
        unless ALLOWED_NODES.any? { |type| node.is_a?(type) }
          raise CompatibilityError, "COMPAT_UNSUPPORTED_STRUCTURE: #{node.class.name}"
        end
        validate_match_node!(node) if node.is_a?(Fbtxt::Parser::MatchLine)
      end
    end

    def structural_contexts(tree)
      defined_groups = tree.grep(Fbtxt::Parser::GroupDef).map(&:name)
      current_group = nil
      current_round = nil
      contexts = []

      tree.each do |node|
        next unless node.is_a?(Fbtxt::Parser::RoundOutline) || node.is_a?(Fbtxt::Parser::MatchLine)

        if node.is_a?(Fbtxt::Parser::MatchLine)
          contexts << { round: current_round, group: current_group, source_score: node.score }
          next
        end

        if node.level == 1 && defined_groups.include?(node.outline)
          current_group = node.outline
          current_round = nil
        elsif node.level == 1
          if node.outline.match?(/\AGroup\s+[A-Za-z0-9]+\z/i)
            raise CompatibilityError, "COMPAT_AMBIGUOUS_GROUP: no definition found for #{node.outline}"
          end
          current_group = nil
          current_round = node.outline
        elsif node.level == 2 && current_group
          current_round = node.outline
        else
          raise CompatibilityError, "COMPAT_UNSUPPORTED_NESTING: round level #{node.level} is not a proven group/round structure"
        end
      end
      contexts
    end

    def validate_match_node!(node)
      if blank?(node.team1) || blank?(node.team2)
        raise CompatibilityError, 'COMPAT_MISSING_TEAMS: every imported match requires two teams'
      end

      score = node.score
      if score.is_a?(Array)
        score = { ft: score }
      end
      return if score.nil?
      unless score.is_a?(Hash)
        raise CompatibilityError, "COMPAT_UNSUPPORTED_SCORE: #{score.class.name}"
      end
      if score.key?(:agg) || score.key?('agg')
        raise CompatibilityError, 'COMPAT_UNSUPPORTED_AGG: aggregate scores have no models_v2 database field'
      end

      unknown = score.keys.map(&:to_sym) - %i[ft ht et p]
      unless unknown.empty?
        raise CompatibilityError, "COMPAT_UNSUPPORTED_SCORE_KEYS: #{unknown.join(', ')}"
      end
    end

    def reject_converter_errors!(errors)
      return if errors.empty?

      raise CompatibilityError, "COMPAT_CONVERTER_ERROR: #{errors.map(&:to_s).join(' | ')}"
    end

    def build_legacy_match(match, context)
      if blank?(match.team1) || blank?(match.team2)
        raise CompatibilityError, 'COMPAT_MISSING_TEAMS: every imported match requires two teams'
      end
      if blank?(match.date)
        raise CompatibilityError, 'COMPAT_MISSING_DATE: every imported match requires an explicit or inherited date'
      end
      if context[:group] && blank?(context[:round])
        raise CompatibilityError, 'COMPAT_AMBIGUOUS_STRUCTURE: group without round cannot be represented by models_v2'
      end

      score = match.score
      if context[:source_score].nil? && score == []
        score = {}
      elsif score.is_a?(Array)
        score = { ft: score }
      end
      score ||= {}

      Sports::Match.new(
        num: match.num,
        date: match.date,
        time: match.time,
        team1: match.team1,
        team2: match.team2,
        round: context[:round],
        group: context[:group],
        status: match.status,
        score1: pair(score, :ft, 0),
        score2: pair(score, :ft, 1),
        score1i: pair(score, :ht, 0),
        score2i: pair(score, :ht, 1),
        score1et: pair(score, :et, 0),
        score2et: pair(score, :et, 1),
        score1p: pair(score, :p, 0),
        score2p: pair(score, :p, 1)
      )
    end

    def pair(score, key, index)
      value = score[key] || score[key.to_s]
      return nil if value.nil?
      unless value.is_a?(Array) && value.length == 2 && value.all? { |part| part.is_a?(Integer) }
        raise CompatibilityError, "COMPAT_INVALID_#{key.to_s.upcase}: expected an integer pair"
      end
      value[index]
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end

  class QuickLeagueOutline
    Section = Struct.new(:league, :season, :stage, :lines, keyword_init: true) do
      def text
        "#{lines.join("\n")}\n"
      end
    end

    def self.parse(text)
      new(text).tap(&:preflight!)
    end

    def initialize(text)
      @sections = partition(text)
    end

    def each_sec(&block)
      return enum_for(:each_sec) unless block
      @sections.each(&block)
    end

    def preflight!
      @sections.each do |section|
        if section.lines.none? { |line| !line.strip.empty? }
          raise CompatibilityError, 'COMPAT_EMPTY_SECTION: every league/stage section requires match content'
        end
        start = season_start(section.season)
        _teams, matches, _rounds, _groups = MatchParser.new(section.lines, start).parse
        if matches.empty?
          raise CompatibilityError, 'COMPAT_EMPTY_SECTION: no importable matches found'
        end
        if section.stage && matches.any? { |match| match.round.nil? || match.round.to_s.strip.empty? }
          raise CompatibilityError, 'COMPAT_AMBIGUOUS_STAGE: models_v2 requires a round when a stage is present'
        end
      end
      self
    end

    private

    HEADING1 = /\A=\s+(.+?)\s+((?:\d{4})(?:[\/-]\d{2,4})?)\s*\z/
    HEADING2 = /\A==\s+(.+?)\s*\z/

    def partition(text)
      sections = []
      league = season = stage = nil
      lines = nil

      text.each_line(chomp: true).with_index(1) do |line, line_number|
        case line
        when /\A===\s+/
          raise CompatibilityError, "COMPAT_UNSUPPORTED_NESTING: heading level 3 at line #{line_number}"
        when HEADING2
          ensure_heading_context!(league, season, line_number)
          flush_section!(sections, league, season, stage, lines) if meaningful?(lines)
          stage = Regexp.last_match(1).strip
          raise CompatibilityError, "COMPAT_AMBIGUOUS_STAGE: empty stage at line #{line_number}" if stage.empty?
          lines = []
        when HEADING1
          flush_section!(sections, league, season, stage, lines)
          league = Regexp.last_match(1).strip
          season = Regexp.last_match(2).strip
          stage = nil
          lines = []
        when /\A=\s+/
          raise CompatibilityError, "COMPAT_AMBIGUOUS_HEADING: league and season not proven at line #{line_number}"
        else
          if lines.nil?
            next if line.strip.empty? || line.lstrip.start_with?('#')
            raise CompatibilityError, "COMPAT_CONTENT_BEFORE_HEADING: line #{line_number}"
          end
          lines << line
        end
      end

      flush_section!(sections, league, season, stage, lines)
      raise CompatibilityError, 'COMPAT_MISSING_HEADING: no league/season heading found' if sections.empty?
      sections
    end

    def flush_section!(sections, league, season, stage, lines)
      return if lines.nil?
      sections << Section.new(league: league, season: season, stage: stage, lines: lines)
    end

    def meaningful?(lines)
      lines && lines.any? { |line| !line.strip.empty? && !line.lstrip.start_with?('#') }
    end

    def ensure_heading_context!(league, season, line_number)
      return if league && season
      raise CompatibilityError, "COMPAT_STAGE_WITHOUT_LEAGUE: line #{line_number}"
    end

    def season_start(season)
      match = /\A(\d{4})(?:[\/-](\d{2,4}))?\z/.match(season)
      raise CompatibilityError, "COMPAT_INVALID_SEASON: #{season}" unless match
      month = match[2] ? 7 : 1
      Date.new(match[1].to_i, month, 1)
    end
  end
end
