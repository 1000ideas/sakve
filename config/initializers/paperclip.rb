Paperclip.configure do |config|
  config.interpolates :partition do |attachment, style|
    "#{Rails.root}/uploads"
  end

  config.interpolates :token do |attachment, style|
    attachment.instance.token
  end

  config.interpolates :name do |attachment, style|
    attachment.instance.name.parameterize
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
  config.jod_path = Rails.root.join('vendor', 'jodconverter', 'jodconverter-3.0.1.jar')
end

