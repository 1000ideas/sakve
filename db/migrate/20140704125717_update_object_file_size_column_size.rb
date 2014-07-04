class UpdateObjectFileSizeColumnSize < ActiveRecord::Migration
  def up
    change_column(:transfers, :object_file_size, :integer, limit: 8)
    change_column(:transfer_files, :object_file_size, :integer, limit: 8)
  end

  def down
    change_column(:transfers, :object_file_size, :integer)
    change_column(:transfer_files, :object_file_size, :integer)
  end
end
