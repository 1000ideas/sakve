class CopyUploadedFileWorker
  include Sidekiq::Worker

  def perform(id, path)
    @transfer_file = TransferFile.find(id)
    file = File.open(path, 'rb')
    @transfer_file.update_attributes(object: file, upload_status: :done)
    File.unlink(path) if File.exists?(path)
  rescue Errno::ENOENT
    logger.error "File '#{path}' doesn't exists. Mark upload as failed!"
    @transfer_file.update_attributes(upload_status: :fail) if @transfer_file
  rescue ActiveRecord::RecordNotFound
    logger.error "TransferFile##{id} doesn't exists. Skip upload."
  end

end
