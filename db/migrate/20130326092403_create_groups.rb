class CreateGroups < ActiveRecord::Migration
  def up
    create_table :groups do |t|
      t.string :name
      t.string :title
      t.string :description

      t.timestamps
    end

    Group.create_translation_table! title: :string, description: :string
  end

  def down
    Group.drop_translation_table!
    drop_table :groups

  end
end
