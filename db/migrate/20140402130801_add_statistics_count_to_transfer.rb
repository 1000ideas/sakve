class AddStatisticsCountToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :statistics_count, :integer, default: 0
  end
end
