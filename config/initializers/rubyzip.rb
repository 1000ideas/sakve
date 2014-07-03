require 'zip'

Zip.setup do |config|
  #Use unicode names
  config.unicode_names = true

  #Fastet compression, biggest files
  config.default_compression = ::Zlib::BEST_SPEED

  #Enable zip64 support
  config.write_zip64_support = true
end
