require 'sakve'

sidekiq_config = { url: ENV['JOB_WORKER_URL'] || 'redis://redis:6379/0', namespace: 'sakve' }

Sidekiq.configure_server do |config|
  ActiveRecord::Base.logger = Sidekiq.logger
  config.redis = { url: ENV['JOB_WORKER_URL'] || 'unix:/var/run/redis/redis.sock', namespace: 'sakve' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['JOB_WORKER_URL'] || 'unix:/var/run/redis/redis.sock', namespace: 'sakve' }
end

class Dir
  def self.tmpdir
    @@tmpdir ||= Rails.root.join('upload_tmp').to_s
  end
end
