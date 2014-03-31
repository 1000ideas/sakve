class CreateSelectionDownloads < ActiveRecord::Migration
  def change
    create_table :selection_downloads, id: false do |t|
      t.string :id, limit: 32
      t.integer :user_id
      t.text :ids
      t.text :fids
      t.boolean :done, default: false

      t.timestamps
    end

    add_index :selection_downloads, :id
  end
end
