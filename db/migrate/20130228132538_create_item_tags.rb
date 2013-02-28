class CreateItemTags < ActiveRecord::Migration
  def change
    create_table :item_tags do |t|
      t.integer :item_id, null: false
      t.integer :tag_id, null: false

      t.timestamps
    end

    add_index :item_tags, [:item_id, :tag_id], unique: true
  end
end
