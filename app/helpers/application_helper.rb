module ApplicationHelper

  def sort_link(name, title = nil, options = {})
    title ||= t(name, scope: :sortbar)
    direction = :asc

    class_name = [:sort, options.delete(:class)].compact

    if params[:sort].try(:[], :column).try(:to_sym) == name
      direction = params[:sort].try(:[], :dir) == 'asc' ? :desc : :asc
      class_name << :current
      class_name << direction
    end

    options[:class] = class_name

    link_to title, {sort: {column: name, dir: direction}}, options
  end

  def cp(path)
    'active' if current_page?(path)
  end

  def render_html(*args, &block)
    _formats = self.formats
    self.formats = [:html]
    render(*args, &block)
  ensure
    self.formats = _formats
  end

  def logo_tag
    content_tag(:div, class: :logo) do
      [
        link_to( image_tag('1000i-logo.svg'), 'http://1000i.pl', target: '_blank' ),
        link_to( image_tag('sakve-logo.svg'), root_path )
      ].join.html_safe
    end
  end

  def folder_classes(folder)
    class_name = [:folder]
    class_name << :current if @current_folder == folder
    class_name << :'not-empty' if folder.subfolders.any?
    class_name << :open if folder.ancestor?(@current_folder)
    class_name.join(' ')
  end

  def file_upload_tag(name, options = {})
    options.merge!(
      multiple: true,
      data: { value: t('.fileupload', default: 'Select files') }
    )
    file_field_tag(name, options)
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
