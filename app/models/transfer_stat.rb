class TransferStat < ActiveRecord::Base
  belongs_to :transfer, counter_cache: :statistics_count
  attr_accessible :browser, :client_ip
end
