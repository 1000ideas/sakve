class User < ActiveRecord::Base
  has_many :items, dependent: :destroy
  has_many :folder, dependent: :destroy

  rolify
  devise :database_authenticatable, :timeoutable,
         :rememberable, :trackable, :registerable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :set_role

  validates :email, :presence => true
  validates :email, :uniqueness => true
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates :password, :presence => true, :confirmation => true, :length => {:minimum => 5}, :on => :create
  validates :password, :allow_blank => true, :confirmation => true, :length => {:minimum => 5}, :on => :update


  def to_s 
    email
  end

  def role
    if has_role?(:admin)
      "admin"
    elsif has_role?(:user)
      "user"
    elsif has_any_role?
      "norole"
    end
  end
  alias_attribute :set_role, :role

  def set_role=(value)
    roles.destroy
    add_role(value.to_sym)
  end

  def admin?
    has_role?(:admin)
  end

end
