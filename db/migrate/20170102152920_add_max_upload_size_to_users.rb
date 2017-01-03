class AddMaxUploadSizeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_upload_size, :decimal, default: 10
  end
end
