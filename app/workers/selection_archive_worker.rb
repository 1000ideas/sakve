class SelectionArchiveWorker
  include Sidekiq::Worker

  def perform(token)
    selection = SelectionDownload.find(token)
    selection.create_archive
  end
end
