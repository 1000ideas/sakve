class CloudTransferWorker
  class WorkerArgumentError < ArgumentError; end

  include Sidekiq::Worker

  @@required_options = {
    folder_id: Folder,
    item_id: Item,
    selection_id: SelectionDownload
  }
  cattr_reader :required_options

  def perform(transfer_id, options)
    options.symbolize_keys!

    @element = self.class.required_options.reduce(nil) do |memo, pair|
      memo || if options.has_key?(pair.first)
        pair.second.find(options[pair.first])
      end
    end

    if @element.nil?
      raise WorkerArgumentError, "One of this options are required: #{self.class.required_options.keys.join(', ')}."
    end

    @transfer = Transfer.find(transfer_id)
    @transfer.update_attributes object: @element.send(:file_for_transfer),
      done: true

  rescue WorkerArgumentError => ex
    logger.error ex
  end
end
