$LOAD_PATH.unshift(File.expand_path('../vendor/rsssf-scripts/rsssf/lib', __dir__))

require 'webget'
require 'rsssf'
require 'fileutils'

class OfficialSeasonPreparer
  def initialize(source_path, output_path)
    @source_path = source_path
    @output_path = output_path
  end

  def run
    puts "Ejecutando Rsssf::Fmtfix.fmtfix oficial de Gerald Bauer sobre #{@source_path}..."
    raw_txt = File.read(@source_path, encoding: 'UTF-8')

    # Run official Rsssf::Fmtfix engine
    fmtfix_txt = Rsssf::Fmtfix.fmtfix(raw_txt)

    # Extract ONLY Primera División Apertura & Clausura sections from official fmtfix output
    output_lines = []
    output_lines << "= Argentina | Primera División 2025"
    output_lines << ""

    in_target_stage = false

    fmtfix_txt.lines.each do |line|
      line_clean = line.strip

      # Stop at non-Primera sections like Tabla Anual, Copa Argentina, Primera B, etc.
      if line_clean =~ /^(===|\=\=)\s*(Tabla Anual|Trofeo de Campeones|Copa Argentina|Campeonato de Primera|Torneo Federal|CFFA|National Teams)/i
        in_target_stage = false
        next
      end

      # Detect Primera División Apertura and Clausura
      if line_clean =~ /^(===|\=\=)\s*(Torneo Apertura|Torneo Clausura)/i
        stage_name = line_clean.include?('Apertura') ? 'Torneo Apertura' : 'Torneo Clausura'
        output_lines << "== #{stage_name}"
        output_lines << ""
        in_target_stage = true
        next
      end

      if in_target_stage
        output_lines << line.chomp
      end
    end

    final_txt = output_lines.join("\n") + "\n"

    FileUtils.mkdir_p(File.dirname(@output_path))
    File.write(@output_path, final_txt, encoding: 'UTF-8')
    puts "Wrote official extracted Primera División dataset to #{@output_path}"
  end
end

if __FILE__ == $0
  source = File.join(__dir__, '..', 'sources', 'rsssf', '2025', 'arg2025.txt')
  output = File.join(__dir__, '..', 'data', 'primera', '2025', '2025.txt')

  OfficialSeasonPreparer.new(source, output).run
end
