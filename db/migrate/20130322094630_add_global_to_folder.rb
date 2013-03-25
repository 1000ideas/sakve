class AddGlobalToFolder < ActiveRecord::Migration
  def change
    add_column :folders, :global, :boolean, null: false, default: false
  end
end
