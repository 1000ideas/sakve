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

    link_to title, {folder: @current_folder_id, sort: {column: name, dir: direction}}, options
  end

  def cp(path)
    if path.kind_of? Hash
      'active' if path.inject(true) {|memo, val| memo && send(:"#{val.first}_name").to_sym == val.last }
    else
      'active' if current_page?(path)
    end
  end

  def render_html(*args, &block)
    _formats = self.formats
    self.formats = [:html]
    render(*args, &block)
  ensure
    self.formats = _formats
  end

  def logo_tag(path = root_path)
    content_tag(:div, class: :logo) do
      [
        link_to( image_tag('1000i-logo.svg'), path ),
        link_to( image_tag('sakve-logo.svg'), path )
      ].join.html_safe
    end
  end

  def folder_classes(folder)
    class_name = [:folder]
    class_name << :current if @current_folder == folder
    class_name << :'not-empty' if (RUBY_VERSION >= '2.2.0' ? !folder.subfolders.compact.empty? : folder.subfolders.any?) # some issues with 'any?' in ruby 2.2.5
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

  def space_used_percent(user)
    return 0 if user.max_upload_size.nil?

    ((user.files_uploaded_size.to_f / user.max_upload.to_f * 100.0).round(-1) / 10).to_s
  end

  def allowed_upload_size(user)
    return (user.max_upload - user.files_uploaded_size) if user.max_transfer_size.nil?
    return user.max_transfer if user.max_upload_size.nil?

    [user.max_upload - user.files_uploaded_size, user.max_transfer].min
  end
end
