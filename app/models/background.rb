class Background < ActiveRecord::Base
  attr_accessible :download, :upload, :link, :image, :active

  has_attached_file :image, styles: { thumbnail: "200x200" }

  validates :image, attachment_presence: true
  validates :image, attachment_content_type: { content_type: /\Aimage/i }
end
