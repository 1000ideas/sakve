class CreateTransferStats < ActiveRecord::Migration
  def change
    create_table :transfer_stats do |t|
      t.references :transfer
      t.string :client_ip, limit: 15
      t.text :browser

      t.timestamps
    end
    add_index :transfer_stats, :transfer_id
  end
end
