class User < ActiveRecord::Base
  @@_root_folders = {}
  @@showable_attributes = %w(name email)
  mattr_reader :showable_attributes

  has_many :user_groups, include: :group
  has_many :groups, through: :user_groups
  has_many :items, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :shares, as: :collaborator
  has_many :shared_items, through: :shares, source: :resource, source_type: 'Item'
  has_many :selection_downloads
  # has_many :shared_folders, through: :shares, source: :resource, source_type: 'Folder'
  has_many :transfers

  scope :starts_with, lambda { |query|
    where('`first_name` like :q OR `last_name` LIKE :q OR `email` LIKE :q', q: "#{query}%")
  }

  devise :database_authenticatable, :rememberable,
    :trackable, :registerable, :recoverable, :validatable,
    :timeoutable

  attr_accessor :updated_by
  attr_accessible :first_name, :last_name, :name, :email,
    :password, :password_confirmation, :remember_me, :group_ids,
    :reset_password_sent_at, :reset_password_token

  after_create :create_private_folder

  validates :email, :presence => true
  validates :email, :uniqueness => true
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates :password, :presence => true, :confirmation => true, :length => {:minimum => 5}, :on => :create
  validates :password, :allow_blank => true, :confirmation => true, :length => {:minimum => 5}, :on => :update
  validates :first_name, :last_name, presence: true

  def auth_token
    read_attribute(:auth_token) || begin
      update_column :auth_token, SecureRandom.hex(16)
      read_attribute(:auth_token)
    end
  end

  def shared_folders
    Folder.shared_for_user(self) | Folder.shared_for_groups(self)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def name=(value)
    self.first_name, self.last_name = value.split(/\s+/, 2)
  end

  def to_s
    "#{name} <#{email}>"
  end

  def add_group(name)
    group = Group.where(name: name).first || Group.create(name: name, title: name.to_s.titleize)
    user_groups.find_or_create_by_user_id_and_group_id(self.id, group.id)
    group
  end

  def belongs_to_group? name
    groups.any? {|g| g.name === name }
  end

  def admin?
    belongs_to_group? :admin
  end

  def has_shared_items?
    self.groups.inject( self.shared_items.any? ) do |memo, group|
      memo || group.shared_items.any?
    end
  end

  def active_for_authentication?
    super && !banned? && active?
  end

  def inactive_message
    if banned?
      :banned
    elsif !active?
      :inactive
    else
      super
    end
  end

  def ban!
    self.banned_at = DateTime.now
    self.save
  end

  def unban!
    self.banned_at = nil
    self.save
  end

  def banned?
    self.banned_at.present?
  end

  def activate!
    self.activated_at = DateTime.now
    self.save
  end

  def active?
    self.activated_at.present?
  end

  def root_folder(unchached = false)
    @@_root_folders.delete(self.id) if unchached
    @@_root_folders[self.id] ||= self.folders(parent_id: nil, global: false).first
  end

  def clear_root_folder_cache!
    @@_root_folders.delete(self.id)
  end

  def label_or_error(field)
    if errors.include?(field)
      errors.full_message(field, errors[field].first)
    else
      self.class.human_attribute_name(field)
    end
  end

protected

  def create_private_folder
    Folder.create!(user_id: self.id, global: false)
  end

  def updated_by_admin?
    updated_by.present? and updated_by.admin?
  end

  def password_required?
    super && !updated_by_admin?
  end

end
