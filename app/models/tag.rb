class Tag < ActiveRecord::Base
  has_many :item_tags
  has_many :items, through: :item_tags

  attr_accessible :name

  validates :name, presence: true

  def to_s
    name
  end

  def self.from_list(list)
    list.split(/,\s*/).map do |tag|
      self.where(name: tag).first || self.create(name: tag)
    end
  end
end
