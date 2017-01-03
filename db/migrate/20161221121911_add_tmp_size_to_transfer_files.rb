class AddTmpSizeToTransferFiles < ActiveRecord::Migration
  def change
    add_column :transfer_files, :tmp_size, :integer, limit: 8
  end
end
