class Item < ActiveRecord::Base
  include Sakve::ItemTypes

  belongs_to :user
  belongs_to :folder
  has_many :item_tags, include: :tag, dependent: :destroy
  has_many :tags, through: :item_tags

  has_attached_file :object, 
    styles: Proc.new {|object| object.instance.item_styles } ,
    processors: [:item_processor],
    path: ':partition/:class/:id/:style/:filename',
    url: '/:class/:id/download/:style.:extension'

  before_save :fix_mime_type, :save_tags, :default_name

  attr_accessible :name, :object, :type, :user_id, :tags, :folder_id, :folder

  validates :object, attachment_presence: true
  validates :folder_id, presence: true


  def item_styles
    styles = {
      thumb: ['128x128#', :png]
    }
    if video?
      styles[:preview] = ['640x480>', :mp4]
      styles[:flash] = ['640x480>', :flv]
    elsif presentation?
      styles[:preview] = ['200', :pdf]
    elsif image? or pdf_document?
      styles[:preview] = ['640x480>', :png]
    end
    styles
  end

  def thumb
    object.url(:thumb)
  end

  alias :tags_list :tags

  def tags=(value)
    @tags = value
  end

  def tags
    @tags || tags_list.join(', ')
  end

  def self.search_by_tags(*tags)
    tags = tags.flatten
    return [] if tags.empty?
    assoc = self.reflect_on_association(:tags)
    self.joins(:tags).
      where(assoc.table_name.to_sym => {name: tags}).
      group("#{table_name}.id").
      having("COUNT(`#{assoc.table_name}`.`#{assoc.association_primary_key}`) = ?", tags.size)
  end

  def self.search_by_name(*words)
    words = words.flatten
    return [] if words.empty?
    words.inject(self) do |result, w|
      result.where("`#{table_name}`.`name` LIKE ?", "%#{w}%")
    end
  end

  def self.search(query)
    words = query.query_tokenize
    tags = query.query_tokenize(:tag)

    self.search_by_tags(tags) | self.search_by_name(words)
  end


  protected

  def default_name
    self.name ||= File.basename(object_file_name, '.*').titleize if object?
  end

  def save_tags
    if @tags
      tag_list = @tags.split(',').map(&:strip)
      item_tags.each do |item_tag|
        unless tag_list.include? item_tag.name
          item_tag.destroy
        end
      end
      tag_list.each do |tag|
        t = Tag.where(name: tag).first || Tag.create(name: tag)  
        self.item_tags.create(tag_id: t.id)
      end
    end
  end
end
