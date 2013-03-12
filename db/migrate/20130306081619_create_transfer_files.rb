class CreateTransferFiles < ActiveRecord::Migration
  def change
    create_table :transfer_files do |t|
      t.string :token, limit: 16
      t.integer :user_id
      t.attachment :object

      t.timestamps
    end
  end
end
