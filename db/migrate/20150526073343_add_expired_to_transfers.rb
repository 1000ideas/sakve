class AddExpiredToTransfers < ActiveRecord::Migration
  def change
  	add_column :transfers, :expired, :boolean
  end
end
