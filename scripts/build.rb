require 'fileutils'
require 'sqlite3'

class BuildPipeline
  ROOT = File.expand_path('..', __dir__)
  PREPARE_SCRIPT = File.join(ROOT, 'scripts', 'prepare_2025.rb')
  COMPAT_SCRIPT  = File.join(ROOT, 'compat', 'fbtxt2sqlite_compat.rb')
  DATA_FILE      = File.join(ROOT, 'data', 'primera', '2025', '2025.txt')
  BUILD_DB       = File.join(ROOT, 'build', 'argentina.db')

  def self.run
    puts "=================================================="
    puts "  AFA History v2 — Pipeline Build & Verification  "
    puts "=================================================="

    # Step 1: Prepare Football.TXT dataset
    puts "\n[1/3] Preparando Football.TXT 2026 para la temporada 2025..."
    system("ruby \"#{PREPARE_SCRIPT}\"") || raise("Error al preparar la temporada 2025")

    # Step 2: Validate syntax with fbtok
    puts "\n[2/3] Validando sintaxis Football.TXT con fbtok..."
    fbtok_cmd = "fbtok \"#{DATA_FILE}\""
    system(fbtok_cmd) || raise("Error de validación en fbtok")

    # Step 3: Compile SQLite database
    puts "\n[3/3] Compilando base de datos SQLite build/argentina.db..."
    FileUtils.mkdir_p(File.dirname(BUILD_DB))
    FileUtils.rm_f(BUILD_DB)

    compat_cmd = "ruby \"#{COMPAT_SCRIPT}\" \"#{BUILD_DB}\" \"#{DATA_FILE}\""
    system(compat_cmd) || raise("Error en la compilación a SQLite")

    # Step 4: Verify DB records
    db = SQLite3::Database.new(BUILD_DB)
    leagues = db.get_first_value("SELECT count(*) FROM leagues")
    events  = db.get_first_value("SELECT count(*) FROM events")
    teams   = db.get_first_value("SELECT count(*) FROM teams")
    matches = db.get_first_value("SELECT count(*) FROM matches")
    db.close

    puts "\n=================================================="
    puts "   Build exitoso de build/argentina.db"
    puts "--------------------------------------------------"
    puts "  Ligas (leagues) : #{leagues}"
    puts "  Eventos (events): #{events}"
    puts "  Equipos (teams) : #{teams}"
    puts "  Partidos (matches): #{matches}"
    puts "=================================================="
  end
end

BuildPipeline.run if __FILE__ == $0
