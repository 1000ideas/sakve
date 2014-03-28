class FolderArchiveWorker
  include Sidekiq::Worker

  def perform(folder_id)
    folder = Folder.find(folder_id)

    folder.update_column(:processing, true)
    folder.send(:recreate_zip_file)
  ensure
    folder.update_column(:processing, false)
  end
end
