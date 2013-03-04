class ItemTag < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag, counter_cache: :items_count

  attr_accessible :item_id, :tag_id

  after_destroy :destroy_unused_tags

  validates :item_id, :tag_id, presence: true
  validates :item_id, uniqueness: { scope: :tag_id }

  delegate :name, to: :tag

  protected

  def destroy_unused_tags
    if tag(true).items_count == 0
      tag.destroy
    end
  end
end
