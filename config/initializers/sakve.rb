require 'sakve'

sidekiq_config = { url: ENV['JOB_WORKER_URL'] || 'redis://127.0.0.1:6379/0' }

Sidekiq.configure_server do |config|
  ActiveRecord::Base.logger = Sidekiq.logger
  config.redis = { url: 'unix:/var/run/redis/redis.sock', namespace: 'sakve' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'unix:/var/run/redis/redis.sock', namespace: 'sakve' }
end

class Dir
  def self.tmpdir
    @@tmpdir ||= Rails.root.join('upload_tmp').to_s
  end
end
