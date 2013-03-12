module Sakve::ItemTypes
  def fix_mime_type(force = false)
    if force || object_content_type == 'application/octet-stream'
      object_content_type = Paperclip::ContentTypeDetector.new(object.path).detect
    end
  end

  def video?
    ! object_content_type.match(/^video/).nil?
  end

  def image?
    ! object_content_type.match(/^image/).nil?
  end

  def audio?
    ! object_content_type.match(/^audio/).nil?
  end

  def document?
    ! object_content_type.match(/(word|excel|powerpoint|officedocument|opendocument)/).nil?
  end

  def presentation?
    ! object_content_type.match(/(powerpoint|presentation)$/).nil?
  end

  def spreadsheet?
    ! object_content_type.match(/(excel|spreadsheet)$/).nil?
  end

  def text_document?
    document? && ! object_content_type.match(/word|text/).nil?
  end

  def pdf_document?
    ! object_content_type.match(/pdf$/).nil?
  end

  def archive?
    ! object_content_type.match(/(bzip2$|[gl]zip$|zip$|lzma$|lzop$|xz$|commpress|archive|diskimage$)/).nil?
  end

  def webpage?
   text_file? and ! object_content_type.match(/(css|js|html|xml)/).nil?
  end

  def text_file?
    ! object_content_type.match(/^text/).nil?
  end

  def icon_name
    if video?
      :video
    elsif audio?
      :audio
    elsif image?
      :image
    elsif archive?
      :archive
    elsif presentation?
      :presentation
    elsif spreadsheet?
      :spreadsheet
    elsif text_document?
      :text_document
    elsif webpage?
      :webpage
    elsif text_file?
      :text
    else
      :none
    end
  end
end
