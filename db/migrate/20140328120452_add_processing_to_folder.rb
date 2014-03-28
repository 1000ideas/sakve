class AddProcessingToFolder < ActiveRecord::Migration
  def change
    add_column :folders, :processing, :boolean, default: false
  end
end
