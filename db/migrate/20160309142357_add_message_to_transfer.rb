class AddMessageToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :message, :string
  end
end
