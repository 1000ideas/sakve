class CreateUserBackgrounds < ActiveRecord::Migration
  def change
    create_table :user_backgrounds do |t|
      t.integer :user_id
      t.integer :background_id

      t.timestamps
    end
  end
end
