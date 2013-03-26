class User < ActiveRecord::Base
  has_many :user_groups, include: :group
  has_many :groups, through: :user_groups
  has_many :items, dependent: :destroy
  has_many :folder, dependent: :destroy

  devise :database_authenticatable, :timeoutable,
         :rememberable, :trackable, :registerable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :group_ids

  after_create :create_private_folder

  validates :email, :presence => true
  validates :email, :uniqueness => true
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates :password, :presence => true, :confirmation => true, :length => {:minimum => 5}, :on => :create
  validates :password, :allow_blank => true, :confirmation => true, :length => {:minimum => 5}, :on => :update


  def to_s 
    email
  end

  def add_group(name)
    group = Group.where(name: name).first || Group.create(name: name, title: name.titleize)
    user_groups.find_or_create_by_user_id_and_group_id(self.id, group.id)
    group
  end

  def belongs_to_group? name
    groups.where(name: name).exists?
  end

  def admin?
    belongs_to_group? :admin
  end

protected

  def create_private_folder
    Folder.create!(user_id: self.id) 
  end

end
