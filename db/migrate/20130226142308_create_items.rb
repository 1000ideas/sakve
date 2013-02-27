class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.string :type
      t.attachment :object
    # t.string :object
      t.integer :user_id

      t.timestamps
    end
  end
end
