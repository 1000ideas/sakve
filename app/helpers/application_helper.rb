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

  def folders_breadcrumbs(folder)
    if folder.nil?
      [ link_to( t('items.index.shared'), items_path(folder: :shared)) ]
    elsif folder.global?
      list = [ link_to( t('items.index.public'), items_path) ]
      folder.ancestors(true).reverse.slice(1..-1).each do |f|
        list << link_to(f.name, items_path(folder: f.id) )
      end
      list
    elsif folder.user == current_user
      list = [ link_to( t('items.index.private'), items_path(folder: :user)) ]
      folder.ancestors(true).reverse.slice(1..-1).each do |f|
        list << link_to(f.name, items_path(folder: f.id) )
      end
      list
    else
      list = [ link_to( t('items.index.shared'), items_path(folder: :shared)) ]
      folder.ancestors(true).reverse.slice(1..-1).each do |f|
        list << link_to(f.name, items_path(folder: f.id) ) if f.shared_for? current_user
      end
      list
    end
  end
end
