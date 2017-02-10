class AddMaxTransferSizeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_transfer_size, :float, default: 10.0
  end
end
