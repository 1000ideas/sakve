class User < ActiveRecord::Base
  @@_root_folders = {}
  @@showable_attributes = %w[name email]
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
    :reset_password_sent_at, :reset_password_token, :max_upload_size,
    :max_transfer_size, :tracking_code

  after_create :create_private_folder

  validates :email, presence: true
  validates :email, uniqueness: true
  validates :email, format: { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates :password, presence: true, confirmation: true, length: { minimum: 8 }, on: :create
  validates :password, allow_blank: true, confirmation: true, length: { :minimum => 8 }, on: :update
  validates :first_name, :last_name, presence: true
  validates :max_upload_size, numericality: true, allow_nil: true
  validate :password_complexity

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
    user_groups.find_or_create_by_user_id_and_group_id(id, group.id)
    group
  end

  def belongs_to_group?(name)
    groups.any? { |g| g.name === name }
  end

  def admin?
    belongs_to_group? :admin
  end

  def client?
    belongs_to_group? :client
  end

  def has_shared_items?
    self.groups.inject(RUBY_VERSION >= '2.2.0' ? !self.shared_items.compact.empty? : self.shared_items.any?) do |memo, group|
      memo || (RUBY_VERSION >= '2.2.0' ? !group.shared_items.compact.empty? : group.shared_items.any?) # some issues with 'any?' in ruby 2.2.5
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
    save
  end

  def unban!
    self.banned_at = nil
    save
  end

  def banned?
    banned_at.present?
  end

  def activate!
    self.activated_at = DateTime.now
    save
  end

  def active?
    activated_at.present?
  end

  def root_folder(unchached = false)
    @@_root_folders.delete(id) if unchached
    @@_root_folders[id] ||= self.folders(parent_id: nil, global: false).first
  end

  def clear_root_folder_cache!
    @@_root_folders.delete(id)
  end

  def label_or_error(field)
    if errors.include?(field)
      errors.full_message(field, errors[field].first)
    else
      self.class.human_attribute_name(field)
    end
  end

  def max_upload
    max_upload_size.gigabytes
  end

  def files_uploaded_size
    transfers.active.sum { |t| t.object_file_size.to_i } +
      items.sum { |t| t.object_file_size.to_i }
  end

  def max_transfer
    max_transfer_size.gigabytes
  end

  def last_tracking_code
    transfers
      .where('tracking_code IS NOT NULL').order(id: :desc).limit(1)
      .first.try(:tracking_code)
  end

  protected

  def create_private_folder
    Folder.create!(user_id: id, global: false)
  end

  def updated_by_admin?
    updated_by.present? && updated_by.admin?
  end

  def password_required?
    super && !updated_by_admin?
  end

  def password_complexity
    return if password.blank?

    unless password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).{8,}/)
      errors.add :password, :complexity
    end
  end
end
