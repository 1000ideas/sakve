class AddActiveToBackgrounds < ActiveRecord::Migration
  def change
    add_column :backgrounds, :active, :boolean, default: true
  end
end
