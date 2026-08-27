$LOAD_PATH.unshift(File.expand_path('../vendor/rsssf-scripts/rsssf/lib', __dir__))

require 'webget'
require 'rsssf'
require 'fileutils'
require 'yaml'

class OfficialSeasonPreparer
  def initialize(source_path, aliases_path, output_dir)
    @source_path = source_path
    @output_dir = output_dir
    @alias_map = load_aliases(aliases_path)
  end

  def run
    puts "Ejecutando pipeline oficial de Gerald Bauer sobre #{@source_path}..."
    raw_txt = File.read(@source_path, encoding: 'UTF-8')

    # Step 1: Run official Rsssf::Fmtfix engine
    fmtfix_txt = Rsssf::Fmtfix.fmtfix(raw_txt)

    # Step 2: Extract & split schedules (1-apertura & 2-clausura)
    apertura_lines = extract_first_section(fmtfix_txt, 'Torneo Apertura')
    clausura_lines = extract_first_section(fmtfix_txt, 'Torneo Clausura')

    # Step 3: Format & write each tournament file with official Gerald Bauer metadata # headers
    write_tournament_file('1-apertura.txt', 'Torneo Apertura', apertura_lines)
    write_tournament_file('2-clausura.txt', 'Torneo Clausura', clausura_lines)
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

  def extract_first_section(txt, section_name)
    lines = []
    in_section = false
    found = false

    txt.lines.each do |line|
      line_clean = line.strip

      # Detect section start
      if line_clean =~ /^(===|\=\=)\s*(#{Regexp.escape(section_name)})/i && !found
        in_section = true
        found = true
        next
      end

      # Stop when any new heading begins
      if in_section && line_clean =~ /^(===|\=\=)\s+/
        break
      end

      lines << line.chomp if in_section
    end

    lines
  end

  def normalize_team(name)
    cleaned = name.gsub(/\[.*?\]/, '').strip
    @alias_map[cleaned.downcase] || cleaned
  end

  def clean_venue(venue)
    cleaned = venue.strip.sub(/^pso,?\s*/i, '').tr('"', '').gsub(/\s{2,}/, ' ')
    cleaned = cleaned.sub(/,\s*[A-Z]$/, '').sub(/\s+[A-Z]$/, '').strip
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

  def write_tournament_file(filename, stage_title, content_lines)
    match_count = 0
    teams = {}
    dates = []
    processed_lines = []

    content_lines.each do |line|
      line_clean = line.strip

      # Round header
      if line_clean =~ /^(▪|\=\=|\#\#)\s*(Round|Octavos|Cuartos|Semifinales|Final|Round of 16|Quarter finals|Semi finals)/i || line_clean =~ /^▪\s*.+?\s*▪$/
        processed_lines << line_clean
        next
      end

      # Date header
      if line_clean =~ /^_\s*([A-Za-z]{3}\s+[A-Za-z]{3}\s+\d{1,2})\s*_$/ || line_clean =~ /^\[([A-Za-z]{3})\s+(\d{1,2}),?\s*([A-Za-z]{3})?\]$/
        if line_clean =~ /^\[([A-Za-z]{3})\s+(\d{1,2}),?\s*([A-Za-z]{3})?\]$/
          mon_str = $1
          day_num = $2
          wday_str = $3 || 'Thu'
          date_formatted = "#{wday_str} #{mon_str} #{day_num}"
          dates << date_formatted
          processed_lines << date_formatted
        else
          clean_date = line_clean.tr('_', '').strip
          dates << clean_date
          processed_lines << clean_date
        end
        next
      end

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

        teams[team1] = true
        teams[team2] = true
        match_count += 1

        match_str = "  #{team1}  #{ft1}-#{ft2}, #{p1}-#{p2} pen.  #{team2}"
        match_str += "  @ #{venue_str}" unless venue_str.empty?
        processed_lines << match_str
        next
      end

      # Regular match line: Team A score1- score2 Team B [venue]
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

        teams[team1] = true
        teams[team2] = true
        match_count += 1

        venue_str = clean_venue(venue)
        match_str = "  #{team1}  #{score1}-#{score2}  #{team2}"
        match_str += "  @ #{venue_str}" unless venue_str.empty?
        processed_lines << match_str
        next
      end

      # Preserve notes/comments
      if line_clean.start_with?('#') || line_clean.start_with?('[') || line_clean.empty?
        processed_lines << line_clean
      end
    end

    start_date = dates.first || 'Thu Jan 23'
    end_date = dates.last || 'Sun Jun 1'
    team_count = teams.keys.size > 0 ? teams.keys.size : 30

    out = []
    out << "= Argentina | Primera División 2025"
    out << ""
    out << "# Date       #{start_date} - #{end_date} 2025"
    out << "# Teams      #{team_count}"
    out << "# Matches    #{match_count}"
    out << "# Stages     #{stage_title} (#{match_count})"
    out << ""
    out << "== #{stage_title}"
    out << ""
    out.concat(processed_lines)

    final_path = File.join(@output_dir, filename)
    FileUtils.mkdir_p(@output_dir)
    File.write(final_path, out.join("\n") + "\n", encoding: 'UTF-8')
    puts "Wrote tournament file: #{final_path}"
  end
end

if __FILE__ == $0
  source = File.join(__dir__, '..', 'sources', 'rsssf', '2025', 'arg2025.txt')
  aliases = File.join(__dir__, '..', 'config', 'club_aliases.yml')
  out_dir = File.join(__dir__, '..', 'data', 'primera', '2025')

  OfficialSeasonPreparer.new(source, aliases, out_dir).run
end
