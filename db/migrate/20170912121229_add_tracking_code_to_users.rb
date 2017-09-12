class AddTrackingCodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tracking_code, :boolean, default: false
  end
end
