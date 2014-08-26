class CopyUploadedFileWorker
  include Sidekiq::Worker

  def perform(id, path)
    @transfer_file = TransferFile.find(id)
    if File.exists?(path)
      @transfer_file.update_attributes(object: File.open(path, 'rb'), upload_status: :done)
      File.unlink(path)
    else
      @transfer_file.update_attributes(upload_status: :fail)
    end
  rescue ActiveRecord::RecordNotFound
    logger.error "TransferFile##{id} doesn't exists. Skip upload."
  end

end
