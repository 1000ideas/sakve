class TransferArchiveWorker
  include Sidekiq::Worker

  def perform(token)
    Transfer.find_by_token(token).send(:compress_files).save!
  end
end
