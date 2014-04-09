class AddSubfoldersCountToFolder < ActiveRecord::Migration
  def change
    add_column :folders, :subfolders_count, :integer, default: 0


    FolderTransfer.scoped.each do |f|
      Folder.reset_counters(f.id, :subfolders)
    end
  end
end
