class CreateBackgrounds < ActiveRecord::Migration
  def change
    create_table :backgrounds do |t|
      t.boolean :upload
      t.boolean :download
      t.attachment :image

      t.timestamps
    end
  end
end
