class AddActivatedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :activated_at, :timestamp

    User.update_all(activated_at: DateTime.now)
  end
end
