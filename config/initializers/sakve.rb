require 'sakve'

Sidekiq.configure_server do |config|
  ActiveRecord::Base.logger = Sidekiq.logger
end

Sidekiq.configure_client do |config|

end

class Dir
  def self.tmpdir
    @@tmpdir ||= Rails.root.join('upload_tmp').to_s
  end
end
