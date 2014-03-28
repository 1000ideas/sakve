class ItemProcessWorker
  include Sidekiq::Worker

  def perform(item_id)
    Item.find(item_id).reprocess!
  end
end
