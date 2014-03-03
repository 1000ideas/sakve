class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :parent, class_name: 'Folder'
  has_many :subfolders, class_name: 'Folder', foreign_key: :parent_id
  has_many :items, dependent: :destroy
  has_many :shares, as: :resource
  has_many :users,  through: :shares, source: :collaborator, source_type: 'User'
  has_many :groups,  through: :shares, source: :collaborator, source_type: 'Group'


  attr_accessible :name, :parent_id, :user_id, :user, :parent, :global

  validates :name, presence: true, if: :has_parent?
  validates :name, uniqueness: {scope: [:parent_id, :user_id, :global], case_sensitive: false}, unless: :global?
  validates :name, uniqueness: {scope: [:parent_id, :global], case_sensitive: false}, if: :global?
  validate :only_one_root, unless: :has_parent?

  before_save :ensure_global

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

  def shared_for? user
    users.exists? (user) || user.groups.map {|g| groups.exists?(g) }.inject{|a,b| a || b }
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
    ancestors = []
    ancestors << self if include_self
    p = parent
    until p.nil?
      ancestors << p
      p = p.parent
    end
    ancestors
  end

  def has_subfolders?
    subfolders.count > 0
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

protected

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
