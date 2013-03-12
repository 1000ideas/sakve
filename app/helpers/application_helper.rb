module ApplicationHelper

  def file_upload_tag(name, options = {})
    file_field_tag name, options.merge(
      multiple: true,
      data: { value: t('.fileupload', default: 'Select files') }
    )
  end
end
