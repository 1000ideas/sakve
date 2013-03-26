class Group < ActiveRecord::Base
  PROTECTED_GROUPS = %w(admin mods)

  has_many :user_groups
  has_many :members, through: :user_groups 

  scope :sorted_with_translation, lambda { with_translations(I18n.locale).order("`#{translations_table_name}`.title") }
  translates :title, :description

  before_destroy :disable_deleting_protected_group

  attr_accessible :description, :name, :title, :translations_attributes
  attr_readonly :name

  accepts_nested_attributes_for :translations

  validates :name, presence: true, format: {with: %r{[a-z][a-z0-9]*}}, uniqueness: :true
  validates :title, presence: true

  def build_missing_translations
    I18n.available_locales.map do |l|
      self.translation_for(l, true)
    end
  end

  def protected?
    PROTECTED_GROUPS.include? self.name
  end

  private

  def disable_deleting_protected_group
    ! self.protected?
  end
end
