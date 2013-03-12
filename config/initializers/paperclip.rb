Paperclip.configure do |config|
  config.interpolates :partition do |attachment, style|
    "#{Rails.root}/uploads"
  end

  config.interpolates :token do |attachment, style|
    attachment.instance.token
  end
end

## Run open office
fork do
  exec('soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;StartOffice.Service" --nofirststartwizard')
  exit! 99
end
