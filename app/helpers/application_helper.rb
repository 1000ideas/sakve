module ApplicationHelper

  def file_upload_tag(name, options = {})
    file_field_tag name, options.merge(
      multiple: true,
      data: { value: t('.fileupload', default: 'Select files') }
    )
  end

  def multiselect_tag resource, checked = false, options = {}
    name = resource.class.table_name
    check_box_tag "#{name}[]", resource.id, checked, options.merge(id: "select-#{name}-#{resource.id}")
  end
end
