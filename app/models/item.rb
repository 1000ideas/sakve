class Item < ActiveRecord::Base
  include Sakve::ItemTypes

  belongs_to :user
  belongs_to :folder
  has_many :item_tags, include: :tag, dependent: :destroy
  has_many :tags, through: :item_tags
  has_many :shares, as: :resource
  has_many :users,  through: :shares, source: :collaborator, source_type: 'User'
  has_many :groups,  through: :shares, source: :collaborator, source_type: 'Group'

  scope :shared_for, lambda { |user|
    select("DISTINCT `#{table_name}`.*").joins(:shares).where('(`shares`.`collaborator_type` = ? AND `shares`.`collaborator_id` = ?) OR (`shares`.`collaborator_type` = ? AND `shares`.`collaborator_id` IN (?))', user.class.name, user.id, 'Group', user.group_ids || []).where('`user_id` != ?', user.id)
  }

  has_attached_file :object, 
    styles: Proc.new {|object| object.instance.item_styles } ,
    processors: [:item_processor],
    path: ':partition/:class/:id/:style/:filename',
    url: '/:class/:id/download/:style/:name.:extension'

  before_save :fix_mime_type, :save_tags, :default_name

  attr_accessible :name, :object, :type, :user_id, :user, :tags, :folder_id, :folder

  validates :object, attachment_presence: true
  validates :folder_id, presence: true
  validates :name, uniqueness: { scope: :folder_id, case_sensitive: false }

  def public?
    self.folder.global?
  end

  def shared_for? user
    users.exists?(user) || user.groups.map{|g| groups.exists?(g) }.inject{|a,b| a || b} || folder.shared_for?(user)
  end

  def content_type(style = nil)
    style ||= :original
    MIME::Types.type_for(Item.last.object.path(style)).first.try(:content_type)
  end

  def item_styles
    styles = {
      thumb: ['128x128#', :png]
    }
    if video?
      styles[:mp4] = ['640x480>', :mp4]
      styles[:flash] = ['640x480>', :flv]
      styles[:preview] = ['640x480>', :png]
    elsif image? or pdf_document? or document?
      styles[:preview] = ['640x480>', :png]
    end
    styles[:slides] = ['200', :pdf] if presentation?
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

  def self.access_denied_image(style)

  end

  def name_for_download(extension = nil, increment = nil)
    extension = File.extname(object.original_filename).gsub(/^\./, '') if extension.nil?
    "#{name.parameterize}#{".#{increment}" unless increment.nil?}.#{extension}"
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
