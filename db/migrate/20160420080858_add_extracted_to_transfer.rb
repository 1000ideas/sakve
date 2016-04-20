class AddExtractedToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :extracted, :boolean, default: false
  end
end
