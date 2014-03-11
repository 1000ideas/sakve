class AddTransferToFolder < ActiveRecord::Migration
  def change
    add_column :folders, :transfer_id, :integer
    add_index :folders, :transfer_id
  end
end
