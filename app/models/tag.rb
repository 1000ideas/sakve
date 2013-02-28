class Tag < ActiveRecord::Base
  has_many :item_tags
  has_many :items, through: :item_tags

  attr_accessible :name

  validates :name, presence: true

  def to_s
    name
  end
end
