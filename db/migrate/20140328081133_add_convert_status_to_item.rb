class AddConvertStatusToItem < ActiveRecord::Migration
  def change
    add_column :items, :convert_status, :string, default: Item.statuses.first

    Item.update_all(convert_status: Item.statuses.last)
  end
end
