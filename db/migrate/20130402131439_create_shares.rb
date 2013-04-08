class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer :collaborator_id
      t.string :collaborator_type
      t.integer :resource_id
      t.string :resource_type

      t.timestamps
    end

    add_index :shares, [:collaborator_id, :collaborator_type, :resource_id, :resource_type], unique: true, name: "unique_shares"
  end
end
