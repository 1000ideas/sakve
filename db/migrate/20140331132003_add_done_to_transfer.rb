class AddDoneToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :done, :boolean, default: false
    add_column :transfers, :group_token, :string, limit: 16

    Transfer.update_all(done: true)
  end
end
