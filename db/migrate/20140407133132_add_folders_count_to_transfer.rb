class AddFoldersCountToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :folders_count, :integer, default: 0

    say_with_time("reset folders counter cache") do
      Transfer.scoped.each do |t|
        Transfer.reset_counters(t.id, :folders)
      end
    end
  end
end
