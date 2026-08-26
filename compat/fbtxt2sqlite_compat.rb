require_relative 'openfootball_v2_legacy_adapter'

begin
  load Gem.bin_path('fbtxt2sqlite', 'fbtxt2sqlite')
rescue SportDb::CompatibilityError => error
  warn error.message
  exit 2
end
