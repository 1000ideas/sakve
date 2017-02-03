# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sakve::Application.initialize!

Sakve::Application.configure do
  config.max_upload_time = 14
  config.max_upload_size = 2.gigabytes
end
