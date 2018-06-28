require 'sakve'

sidekiq_config = { url: ENV['SAKVE_REDIS_URL'] || 'redis://localhost:6379/0', namespace: 'sakve' }

Sidekiq.configure_server do |config|
  ActiveRecord::Base.logger = Sidekiq.logger
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end

class Dir
  def self.tmpdir
    @@tmpdir ||= Rails.root.join('upload_tmp').to_s
  end
end
