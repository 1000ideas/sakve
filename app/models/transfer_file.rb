class TransferFile < ActiveRecord::Base
  belongs_to :user

  attr_accessible :object, :token, :user_id, :user

  has_attached_file :object,
    path: ':partition/:class/:token/:id/:filename'

  before_validation :generate_token, on: :create

  validates :token, length: {is: 16}
  validates :user_id, presence: true
  validates :object,
    attachment_presence: true,
    attachment_content_type: { content_type: /.*/i }

  alias_attribute :name, :object_file_name

  scope :loose, lambda { joins("LEFT JOIN `#{Transfer.table_name}` ON `#{table_name}`.`token` = `#{Transfer.table_name}`.`group_token`").where(transfers: {id: nil} )}

  def self.template
    t = self.new
    t.id = ':id'
    t.name = ":name"
    t
  end

  def psd?
    !!object.content_type.match(%r{(photoshop|psd)$})
  end

  private

  def generate_token
    if self.token.blank?
      begin
        self.token = SecureRandom.hex(8)
      end until self.class.where(token: self.token).empty?
    end
  end
end
