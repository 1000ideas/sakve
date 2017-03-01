class Group < ActiveRecord::Base
  class Symbolizer
    class << self
      def load(value)
        value.to_sym if value
      end

      def dump(value)
        value.to_s if value
      end
    end
  end

  @@protected_groups = %w(admin mods clients)
  mattr_reader :protected_groups

  has_many :user_groups
  has_many :members, through: :user_groups
  has_many :shares, as: :collaborator
  has_many :shared_items, through: :shares, source: :resource, source_type: 'Item'
  has_many :shared_folders, through: :shares, source: :resource, source_type: 'Folder'

  scope :sorted_with_translation, lambda { with_translations(I18n.locale).order("`#{translations_table_name}`.title") }

  scope :starts_with, lambda { |query|
    with_translations(I18n.locale).where("`name` like :q OR `#{translations_table_name}`.`title` LIKE :q", q: "#{query}%")
  }

  translates :title, :description

  before_destroy :disable_deleting_protected_group

  attr_accessible :description, :name, :title, :translations_attributes
  attr_readonly :name

  accepts_nested_attributes_for :translations

  validates :name, presence: true, format: {with: %r{[a-z][a-z0-9]*}}, uniqueness: :true
  validates :title, presence: true

  serialize :name, Symbolizer

  def to_s
    title
  end

  def build_missing_translations
    I18n.available_locales.map do |l|
      self.translation_for(l, true)
    end
  end

  def protected?
    @@protected_groups.include? self.name
  end

  private

  def disable_deleting_protected_group
    !self.protected?
  end
end
