class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :parent, class_name: 'Folder'
  has_many :subfolders, class_name: 'Folder', foreign_key: :parent_id
  has_many :items, dependent: :destroy
  has_many :shares, as: :resource
  has_many :users,  through: :shares, source: :collaborator, source_type: 'User'
  has_many :groups,  through: :shares, source: :collaborator, source_type: 'Group'

  scope :shared_for, lambda { |user|
    select("DISTINCT `#{table_name}`.*").joins(:shares).where('(`shares`.`collaborator_type` = ? AND `shares`.`collaborator_id` = ?) OR (`shares`.`collaborator_type` = ? AND `shares`.`collaborator_id` IN (?))', user.class.name, user.id, 'Group', user.group_ids || []).where('`user_id` != ?', user.id)
  }

  attr_accessible :name, :parent_id, :user_id, :user, :parent, :global

  validates :name, presence: true, if: :has_parent?
  validates :name, uniqueness: {scope: [:parent_id, :user_id, :global], case_sensitive: false}, unless: :global?
  validates :name, uniqueness: {scope: [:parent_id, :global], case_sensitive: false}, if: :global?
  validate :only_one_root, unless: :has_parent?

  before_save :ensure_global

  def shared_for? user
    users.exists? (user) || user.groups.map {|g| groups.exists?(g) }.inject{|a,b| a || b }
  end

  def name_for_select
    name || (global? ? I18n.t('folders.global_root_folder') : I18n.t('folders.user_root_folder'))
  end

  def has_parent?
    ! parent_id.nil?
  end

  def ancestors
    ancestors = []
    p = parent
    until p.nil?
      ancestors << p
      p = p.parent
    end
    ancestors.reverse
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
