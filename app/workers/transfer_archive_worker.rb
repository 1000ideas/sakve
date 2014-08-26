class TransferArchiveWorker
  include Sidekiq::Worker

  def perform(token)
    Transfer.find_by_token(token).tap do |transfer|
      if transfer
        if transfer.files.unfinished.any?
          self.class.perform_in(1.second, token) and return
        else
          transfer.send(:compress_files).save!
        end
      else
        logger.error "Transfer with token #{token} doesn't exist!"
      end
    end
  end
end
