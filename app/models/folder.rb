class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :parent, class_name: 'Folder'
  has_many :subfolders, class_name: 'Folder', foreign_key: :parent_id
  has_many :items, dependent: :destroy
  scope :roots, where(parent_id: nil)
  scope :global_roots, where(parent_id: nil, user_id: nil)
  scope :user_roots, lambda {|user| where(parent_id: nil, user_id: user.id) }

  attr_accessible :name, :parent_id, :user_id, :user, :parent

  validates :name, presence: true, uniqueness: {scope: :parent_id}

  def user=(u)
    user_id = u.id unless u.admin?
  end

  def has_parent?
    ! parent_id.nil?
  end

  def ancestors
    ancestors = []
    p = parent
    unless p.nil?
      ancestors << p
      p = p.parent
    end
    ancestors.reverse
  end

  def has_subfolders?
    subfolders.count > 0 
  end

  def self.names_tree_for_user(user)
    folders = []
    folders += self.global_roots if user.admin?
    folders += self.user_roots(user)
    folders.map(&:for_select_with_children).flatten(1)
  end

  def for_select_with_children(level = 0)
    prefix = '-'*level
    self_name = [ "#{prefix} #{name}", id ]
    [ self_name ] + subfolders.map{|f| f.for_select_with_children(level+1) }.flatten(1)
  end
end
