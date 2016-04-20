class TransferFile < ActiveRecord::Base
  belongs_to :user

  @@upload_statuses = [:new, :fail, :done]
  cattr_reader :upload_statuses

  attr_accessible :object, :token, :user_id, :user, :object_file_name, :upload_status

  scope :uploaded, lambda { where(upload_status: upload_statuses.last) }
  scope :unfinished, lambda { where(upload_status: upload_statuses.first) }
  scope :valid, lambda { where(upload_status: [upload_statuses.first, upload_statuses.last]) }

  has_attached_file :object,
    path: ':partition/:class/:token/:id/:filename'

  before_validation :generate_token, on: :create
  before_post_process :keep_file_name

  validates :token, length: {is: 16}
  validates :user_id, presence: true
  validates :object,
    attachment_content_type: { content_type: /.*/i }

  alias_attribute :name, :object_file_name

  scope :loose, lambda { joins("LEFT JOIN `#{Transfer.table_name}` ON `#{table_name}`.`token` = `#{Transfer.table_name}`.`group_token`").where(transfers: {id: nil} )}

  def self.template
    t = self.new
    t.id = ':id'
    t.name = ":name"
    t
  end

  def upload_status
    read_attribute(:upload_status).try(:to_sym) ||
      write_attribute(:upload_status, self.class.upload_statuses.first)
  end

  def psd?
    object && %r{(photoshop|psd)$} === object.content_type
  end

  private

  def keep_file_name
    if object_file_name_changed? and object_content_type_was.blank?
      self.object.instance_write :file_name, object_file_name_was
    end
  end

  def generate_token
    if self.token.blank?
      begin
        self.token = SecureRandom.hex(8)
      end until self.class.where(token: self.token).empty?
    end
  end
end
