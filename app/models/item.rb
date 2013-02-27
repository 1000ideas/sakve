class Item < ActiveRecord::Base
  belongs_to :user

  has_attached_file :object, 
    styles: Proc.new {|object| object.instance.item_styles } ,
    processors: [:item_processor],
    path: ':partition/:class/:id/:style/:filename',
    url: '/:class/:id/download/:style/:filename'

  before_save :fix_mime_type

  attr_accessible :name, :object, :type, :user_id

  def item_styles
    styles = {
      thumb: ['128x128#', :png],
    }
    if video?
      styles[:preview] = ['640x480>', :mp4]
      styles[:flash] = ['640x480>', :flv]
    elsif presentation?
      styles[:preview] = ['200', :pdf]
    elsif image?
      styles[:preview] = ['640x480>', :png]
    end
    styles
  end

  def thumb
    object.url(:thumb)
  end

  def fix_mime_type(force = false)
    if force || object_content_type == 'application/octet-stream'
      object_content_type = Paperclip::ContentTypeDetector.new(object.path).detect
    end
  end

  def video?
    object_content_type.match /^video/
  end

  def image?
    object_content_type.match /^image/
  end

  def audio?
    object_content_type.match /^audio/
  end

  def document?
    object_content_type.match /(word|excel|powerpoint|officedocument|opendocument)/
  end

  def presentation?
    object_content_type.match /(powerpoint|presentation)$/
  end


end
