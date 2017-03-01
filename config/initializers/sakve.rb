require 'sakve'

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
