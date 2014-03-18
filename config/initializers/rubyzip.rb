require 'zip'

Zip.setup do |config|
  #Use unicode names
  config.unicode_names = true

  #Fastet compression, biggest files
  config.default_compression = ::Zlib::BEST_SPEED
end
