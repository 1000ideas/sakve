Paperclip.configure do |config|
  config.interpolates :partition do |attachment, style|
    "#{Rails.root}/uploads"
  end

  config.interpolates :token do |attachment, style|
    attachment.instance.token
  end

  config.register_processor(:item_processor, PaperclipProcessors::ItemProcessor)
end

# Custom ItemProcesor setup
PaperclipProcessors::ItemProcessor.setup do |config|
  # FFMpeg executable path
  # config.ffmpeg_path = '/usr/bin/ffmpeg'
  
  # FFProbe executable path
  # config.ffprobe_path = '/usr/bin/ffprobe'

  # Java VM executable path
  # config.java_path = '/usr/bin/java'

  # JavaOpenDocument converter library (jar) path
  # config.jod_path = '/usr/share/java/jodconverter/jodconverter-cli-2.2.2.jar'
end

## Run open office
fork do
  exec('soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;StartOffice.Service" --nofirststartwizard')
  exit! 99
end
