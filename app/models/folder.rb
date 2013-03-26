class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :parent, class_name: 'Folder'
  has_many :subfolders, class_name: 'Folder', foreign_key: :parent_id
  has_many :items, dependent: :destroy

  attr_accessible :name, :parent_id, :user_id, :user, :parent, :global

  validates :name, presence: true, if: :has_parent?
  validates :name, uniqueness: {scope: [:parent_id, :user_id, :global], case_sensitive: false}, unless: :global?
  validates :name, uniqueness: {scope: [:parent_id, :global], case_sensitive: false}, if: :global?
  validate :only_one_root, unless: :has_parent?

  def name
    n = super
    if n.blank?
      global? ? I18n.t('folders.global_root_folder') : I18n.t('folders.user_root_folder')
    else
      n
    end
  end

  def global=(value)
    write_attribute(:global,has_parent? ? parent.global : value)
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
    self_name = [ "#{prefix} #{name}", id ]
    [ self_name ] + subfolders.map{|f| f.for_select_with_children(level+1) }.flatten(1)
  end

protected

  def only_one_root
    root_folder = self.class.where(global: global, parent_id: nil)
    root_folder = root_folder.where(user_id: self.user_id) unless global?
    if root_folder.count > 0 
      errors.add(:parent_id, :blank)
    end
  end


end
