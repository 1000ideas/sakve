class AddTrackingCodeToTransfers < ActiveRecord::Migration
  def change
    add_column :transfers, :tracking_code, :text
  end
end
