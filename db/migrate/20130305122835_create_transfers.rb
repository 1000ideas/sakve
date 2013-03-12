class CreateTransfers < ActiveRecord::Migration
  def change
    create_table :transfers do |t|
      t.string :name
      t.string :recipients
      t.integer :user_id
      t.string :token, limit: 64
      t.attachment :object
    # t.string :object
      t.datetime :expires_at

      t.timestamps
    end
  end
end
