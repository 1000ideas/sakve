class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :transfer, conditions: ['`expires_at` >= ?', DateTime.now]
  belongs_to :parent, class_name: 'Folder', touch: true

  has_many :subfolders, class_name: 'Folder', foreign_key: :parent_id
  has_many :items, dependent: :destroy
  has_many :shares, as: :resource
  has_many :users,  through: :shares, source: :collaborator, source_type: 'User'
  has_many :groups,  through: :shares, source: :collaborator, source_type: 'Group'


  attr_accessible :name, :parent_id, :user_id, :user, :parent, :global,
    :transfer_id

  validates :name, presence: true, if: :has_parent?
  validates :name, uniqueness: {scope: [:parent_id, :user_id, :global], case_sensitive: false}, unless: :global?
  validates :name, uniqueness: {scope: [:parent_id, :global], case_sensitive: false}, if: :global?
  validate :only_one_root, unless: :has_parent?
  validate :loop_in_hierarchy

  before_save :ensure_global
  alias_method :fid, :id

  scope :shared_for, lambda { |user|
    joins(:shares)
      .group("`#{table_name}`.`id`")
      .where(%{
        (`#{Share.table_name}`.`collaborator_type` = 'User'
          AND `#{Share.table_name}`.`collaborator_id` = ?)
        OR (`#{Share.table_name}`.`collaborator_type` = 'Group'
          AND `#{Share.table_name}`.`collaborator_id` IN (#{user.groups.select("`#{user.groups.table_name}`.`id`").to_sql}))
      }.gsub($/, ''), user)
      .where("`#{table_name}`.`user_id` != ?", user.id)
  }

  scope :allowed_for, lambda { |user|
    where(%{`#{table_name}`.`user_id` = :user
      OR `#{table_name}`.`global`
      OR `#{table_name}`.`id` IN (#{shared_for(user).select("`folders`.`id`").to_sql})}.gsub($/, ''),
      user: user)
  }

  def self.search(query)
    words = query.query_tokenize
    return [] if words.empty?
    words.inject(self) do |result, w|
      result.where("`#{table_name}`.`name` LIKE ?", "%#{w}%")
    end
  end

  def self.subaction(selection)
    ba = selection[:subaction]
    raise ArgumentError, "Unknown subaction '#{ba}'" unless methods.grep(/bulk_#{ba}/).any?
    ba
  end

  def self.bulk(selection)
    self
      .where(id: selection[:fids])
      .send(:"bulk_#{subaction(selection)}", selection)
  end

  def self.bulk_tags(selection)
    true #Folders have no tags
  end

  def self.bulk_move(selection)
    output = true
    transaction do
      Rails.logger.debug "#{all.inspect}"
      all.each do |f|
        f.instance_variable_set("@readonly", false)
        f.update_attributes(parent_id: selection[:folder_id])
        if f.errors.any?
          output = f.errors
          raise ActiveRecord::Rollback
        end
      end
    end if any?
    output
  end

  def save_transfer(transfer, user)
    transaction do
      Zip::File.open(transfer.object.path) do |zf|
        tfolder = self.subfolders.create! name: get_child_name(transfer.name),
          user: user,
          transfer_id: transfer.id
        zf.each do |file|
          Rails.logger.debug file.inspect
          file.get_input_stream do |io|
            item = Item.create! object: StringIO.new(io.read),
              object_file_name: file.name.force_encoding('utf-8'),
              folder: tfolder,
              user: user
          end
        end
      end
    end
    true
  end

  def shared_for? user
    users.exists? (user) || user.groups.map {|g| groups.exists?(g) }.inject{|a,b| a || b }
  end

  def allowed_for? user
    global? || user == user || shared_for?(user)
  end


  def name_for_select
    name || (global? ? I18n.t('folders.global_root_folder') : I18n.t('folders.user_root_folder'))
  end

  def has_parent?
    ! parent_id.nil?
  end

  # Pobiera listę folderów nadrzędnych, od najbliższego do najdalszego.
  # Parametd +include_self+ określa czy pierwszym elementem na liscie jest
  # obiekt, czy rodzic
  def ancestors(include_self = false)
    @_ancestors ||= begin
      ancstr = []
      p = parent
      until p.nil?
        ancstr << p
        p = p.parent
      end
      ancstr
    end
    [(self if include_self), *@_ancestors].compact
  end

  def ancestors_until(_folder, include_self = false)
    self.ancestors(include_self).take_while { |f| f != _folder }
  end

  def ancestor?(folder)
    folder.try(:ancestors).try(:include?, self)
  end

  def has_subfolders?
    subfolders.count > 0
  end

  def each_descendant(&block)
    block.call(self)
    subfolders.each do |f|
      f.each_descendant(&block)
    end
  end

  def self.global_root
    Folder.where(global: true, parent_id: nil).first || Folder.create(global: true)
  end

  def self.user_root(user)
    return nil if user.nil?
    Folder.where(global: false, parent_id: nil, user_id: user.id).first
  end


  def self.default(user)
    global_root || user_root(user)
  end

  def self.names_tree_for_user(user)
    folders = []
    folders << self.global_root if user.admin?
    folders << self.user_root(user)
    folders.map{ |f| f.for_select_with_children(-1) }.flatten(1)
  end

  def for_select_with_children(level = 0)
    prefix = level > 0 ? '-'*level : ''
    self_name = [ "#{prefix} #{name_for_select}", id ]
    [ self_name ] + subfolders.map{|f| f.for_select_with_children(level+1) }.flatten(1)
  end

  def zip_file
    filepath = Rails.root.join('folder-zips', "folder-#{id}.zip")
    FileUtils.mkdir_p(filepath.dirname)
    if !File.exists?(filepath) or File.mtime(filepath) < updated_at
      Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
        each_descendant do |f|
          path = f.ancestors_until(self, true).map(&:name).reverse.join('/')
          unless path.blank?
            zipfile.mkdir(path) unless zipfile.find_entry(path)
            Rails.logger.debug "[zip mkdir] #{path}"
            path += '/'
          end
          f.items.each do |item|
            Rails.logger.debug "[zip add] #{path}#{item.name_for_download}"
            zipfile.add("#{path}#{item.name_for_download}", item.object.path) { true }
          end
        end
        zipfile.close
      end
    end
    File.open(filepath, 'rb')
  end

protected

  def get_child_name(name)
    parts = name.split('.')
    ext = parts.pop if parts.size > 1
    orig = parts.join('.')
    it = 1
    while self.subfolders.any? {|f| f.name == name }
      name = ["#{orig}.#{it}", ext].compact.join('.')
      it += 1
    end
    name
  end

  def loop_in_hierarchy
    f = self
    until f.parent.nil?
      errors.add(:parent_id, :invalid) and return false if f.parent == self
      f = f.parent
    end
  end

  def ensure_global
    if has_parent?
      self.global = parent.global
    end
    self
  end

  def only_one_root
    root_folder = self.class.where(global: global, parent_id: nil)
    root_folder = root_folder.where(user_id: self.user_id) unless global?
    if root_folder.count > 0
      errors.add(:parent_id, :blank)
    end
  end


end
