class Background < ActiveRecord::Base
  attr_accessible :download, :upload, :image, :user_ids

  has_many :user_backgrounds, dependent: :destroy
  has_many :users, through: :user_backgrounds

  has_attached_file :image, styles: { thumbnail: "200x200" }

  validates :image, attachment_presence: true
  validates :image, attachment_content_type: { content_type: /\Aimage/i }
end
