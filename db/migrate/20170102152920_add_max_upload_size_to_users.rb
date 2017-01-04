class AddMaxUploadSizeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_upload_size, :float, default: 10.0
  end
end
