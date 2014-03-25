class AddBannedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :banned_at, :timestamp
  end
end
