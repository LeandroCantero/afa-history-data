require 'yaml'
require 'fileutils'

class SeasonPreparer
  def initialize(source_path, aliases_path, output_path)
    @source_path = source_path
    @aliases_path = aliases_path
    @output_path = output_path
    @alias_map = load_aliases(aliases_path)
  end

  def run
    content = File.read(@source_path, encoding: 'UTF-8')
    lines = content.lines

    out_lines = []
    out_lines << "= Argentina | Primera División 2025"
    out_lines << ""

    current_stage = nil
    in_primera_stage = false
    in_table_block = false

    lines.each do |line|
      line_clean = line.strip

      # Detect Stage Headings
      if line_clean.start_with?('=== Torneo Apertura')
        current_stage = 'Torneo Apertura'
        out_lines << "== #{current_stage}"
        out_lines << ""
        in_primera_stage = true
        in_table_block = false
        next
      elsif line_clean.start_with?('=== Torneo Clausura')
        current_stage = 'Torneo Clausura'
        out_lines << "== #{current_stage}"
        out_lines << ""
        in_primera_stage = true
        in_table_block = false
        next
      elsif line_clean.start_with?('===')
        in_primera_stage = false
        in_table_block = false
        next
      end

      next unless in_primera_stage

      # Skip standings blocks
      if line_clean =~ /^(Table Group|Non official table|#\.Full name|#\.Short name|Tie break:|Champion|Runner-up|Teams eliminated)/
        in_table_block = true
        next
      end

      if in_table_block
        if line_clean =~ /^(Round \d+|Octavos|Cuartos|Semifinales|Final|Round of 16|Quarter finals|Semi finals):?/i
          in_table_block = false
        elsif line_clean =~ /^\d+\./ # Standing line
          next
        elsif line_clean.empty?
          next
        else
          unless line_clean =~ /^(Note:|\[|\d+\s+P\s+)/
            in_table_block = false
          else
            next
          end
        end
      end

      # Round line
      if line_clean =~ /^(Round \d+|Octavos de Final|Cuartos de final|Semifinales|Final|Round of 16|Quarter finals|Semi finals):?/i
        round_name = normalize_round(line_clean)
        out_lines << "▪ #{round_name}"
        next
      end

      # Date header conversion: [Jan 23, Thu] -> Thu Jan 23 2025
      if line_clean =~ /^\[([A-Za-z]{3})\s+(\d{1,2}),?\s*([A-Za-z]{3})?\]$/
        mon_str = $1
        day_num = $2
        wday_str = $3 || 'Thu'
        formatted_date = "#{wday_str} #{mon_str} #{day_num} 2025"
        out_lines << formatted_date
        next
      end

      # Ignore generic bracketed notes
      next if line_clean.start_with?('[') && line_clean.end_with?(']')

      # Match line format with Penalty Shootout (pso): e.g. CA Boca Juniors [4] 0- 0 [2] CA Lanús pso
      if line_clean =~ /^(.+?)\s+\[(\d+)\]\s+(\d+)\s*-\s*(\d+)\s+\[(\d+)\]\s+(.+)$/
        team1_raw = $1.strip
        p1 = $2.strip
        ft1 = $3.strip
        ft2 = $4.strip
        p2 = $5.strip
        rest = $6.strip.sub(/^pso,?\s*/i, '').strip

        team2_raw, venue = split_team2_and_venue(rest)
        team1 = normalize_team(team1_raw)
        team2 = normalize_team(team2_raw)
        venue_str = clean_venue(venue)

        match_str = "  #{team1}  #{ft1}-#{ft2}, #{p1}-#{p2} pen.  #{team2}"
        match_str += "  @ #{venue_str}" unless venue_str.empty?
        out_lines << match_str
        next
      end

      # Abandoned / postponed match line without score: e.g. CA Banfield - CA Independiente abandoned at 0-0...
      if line_clean =~ /^(.+?)\s+-\s+(.+?)\s+(abandoned|postponed|interrupted)/i
        team1_raw = $1.strip
        rest = $2.strip
        status = $3.downcase
        team2_raw, venue = split_team2_and_venue(rest)
        team1 = normalize_team(team1_raw)
        team2 = normalize_team(team2_raw)

        match_str = "  #{team1}  v  #{team2}  [#{status}]"
        out_lines << match_str
        next
      end

      # Regular match line format: Team A score1- score2 Team B [venue]
      if line_clean =~ /^([A-Za-zÁÉÍÓÚáéíóúÑñ\.\s\(\)']+?)\s+(\d+)\s*-\s*(\d+)\s+(.+)$/
        team1_raw = $1.strip
        score1 = $2.strip
        score2 = $3.strip
        rest = $4.strip

        next if team1_raw =~ /^\d+\./

        team2_raw, venue = split_team2_and_venue(rest)

        team1 = normalize_team(team1_raw)
        team2 = normalize_team(team2_raw)

        next if team1.empty? || team2.empty?

        venue_str = clean_venue(venue)
        match_str = "  #{team1}  #{score1}-#{score2}  #{team2}"
        match_str += "  @ #{venue_str}" unless venue_str.empty?
        out_lines << match_str
      end
    end

    FileUtils.mkdir_p(File.dirname(@output_path))
    File.write(@output_path, out_lines.join("\n"), encoding: 'UTF-8')
    puts "Wrote Football.TXT to #{@output_path}"
  end

  private

  def load_aliases(path)
    data = YAML.load_file(path)
    map = {}
    data.each do |_key, info|
      canonical = info['canonical']
      map[canonical.downcase] = canonical
      (info['aliases'] || []).each do |alias_name|
        map[alias_name.downcase] = canonical
      end
    end
    map
  end

  def normalize_round(raw)
    clean = raw.tr(':', '').strip
    case clean
    when /Round of 16|Octavos/i then 'Round of 16'
    when /Quarter finals|Cuartos/i then 'Quarter-finals'
    when /Semi finals|Semifinales/i then 'Semi-finals'
    when /^Final$/i then 'Final'
    else clean
    end
  end

  def normalize_team(name)
    cleaned = name.gsub(/\[.*?\]/, '').strip
    @alias_map[cleaned.downcase] || cleaned
  end

  def clean_venue(venue)
    cleaned = venue.strip.sub(/^pso,?\s*/i, '').tr('"', '').gsub(/\s{2,}/, ' ')
    cleaned = cleaned.sub(/^,\s*/, '').sub(/,\s*[A-Z]$/, '').strip
    cleaned
  end

  def split_team2_and_venue(rest)
    cleaned_rest = rest.sub(/^pso,?\s*/i, '').sub(/^,\s*/, '').strip
    @alias_map.keys.sort_by { |k| -k.length }.each do |alias_lc|
      if cleaned_rest.downcase.start_with?(alias_lc)
        team2 = cleaned_rest[0...alias_lc.length]
        venue = cleaned_rest[alias_lc.length..-1].strip
        return [team2, venue]
      end
    end
    parts = cleaned_rest.split(/\s{2,}/, 2)
    [parts[0], parts[1] || '']
  end
end

if __FILE__ == $0
  source = File.join(__dir__, '..', 'sources', 'rsssf', '2025', 'arg2025.txt')
  aliases = File.join(__dir__, '..', 'config', 'club_aliases.yml')
  output = File.join(__dir__, '..', 'data', 'primera', '2025', '2025.txt')

  SeasonPreparer.new(source, aliases, output).run
end
