class ItemProcessWorker
  include Sidekiq::Worker

  def perform(item_id)
    Item.find(item_id).object.reprocess!
  end
end
