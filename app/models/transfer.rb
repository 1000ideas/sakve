require 'zip'

class Transfer < ActiveRecord::Base

  belongs_to :user
  has_many :folders
  scope :expired, lambda { where('`expires_at` IS NOT NULL AND `expires_at` < ?', DateTime.now) }
  scope :active, lambda { where('`expires_at` IS NULL OR `expires_at` >= ?', DateTime.now) }
  scope :for_user, lambda { |user| user.admin? ? where(true) : where(user_id: user.id) }


  has_attached_file :object,
    path: ':partition/:class/:id/:filename'

  attr_writer :expires_in, :group_token
  attr_accessible :expires_is, :name, :object,
    :recipients, :token, :user_id, :user, :group_token


  #before_validation :compress_files
  before_validation :set_default_name
  before_create :setup_exires_at
  after_create :generate_token, :delete_transfer_files, :send_mail_to_recipients

  validates :token, uniqueness: true
  # validates :name, presence: true
  validates :group_token, presence: true, length: {is: 16}
  validate :valid_recipients
  validates :files, length: {minimum: 1}, if: Proc.new { |a| a.token.blank? }
  validates :object, attachment_presence: true,
    attachment_content_type: { content_type: /.*/i }

  def expires_in
    if expires_at.present?
      ((expires_at.to_datetime - DateTime.now)/1.day).ceil
    end
  end

  def group_token
    @group_token ||= last_user_group_token || SecureRandom.hex(8)
  end

  def group_token=(value)
    @group_token = value
    compress_files
    group_token
  end

  def saved_by_user(user)
    folders.where(user_id: user.id).first
  end

  def content
    Zip::File.open(object.path) do |f|
      f.entries.map do |entry|
        entry.name
      end
    end
  end

  def files
    TransferFile.where(token: group_token)
  end

  def self.delete_expired
    self.expired.each(&:destroy)
  end

  def recipients_list
    if recipients.kind_of?(String)
      recipients.split(/[,\s]+/).sort
    else
      []
    end
  end

  def forever?
    expires_at.nil?
  end

  def expired?
    expires_at.present? and expires_at < DateTime.now
  end

  def expiration_distance
    if expires_at.present?
      ActionController::Base.helpers.distance_of_time_in_words(Time.now, self.expires_at).to_s
    else
      I18n.t('transfers.index.infinite')
    end
  end

  private

  def last_user_group_token
    TransferFile.where(user_id: user_id).first.try(:token)
  end

  def generate_token
    saved = self.update_attributes( token: SecureRandom.hex(32) ) until saved
  end

  def valid_recipients
    recipient_count = 0
    self.recipients.try(:split, /[,\s]+/).try(:each) do |email|
      recipient_count += 1
      unless email.match /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        self.errors.add(:recipients, :invalid)
        break
      end
    end
    # self.errors.add(:recipients, :too_short, count: 1) unless recipient_count > 0
  end

  def compress_files
    if group_token && ! self.object?
      self.object = TransferFile.compress(group_token)
      self.object.instance_write :file_name,  file_name_from_title
      @delete_files = true
    end
  end

  def file_name_from_title(ext = :zip)
    name = self.name.try(:parameterize)
    name = "quicktransfer-#{token || group_token}" if name.blank?
    "#{name}.#{ext}"
  end

  def delete_transfer_files
    self.files.each(&:destroy) if @delete_files
  end

  def send_mail_to_recipients
    TransferMailer.after_create(self).deliver if recipients_list.any?
  end

  def setup_exires_at
    if expires_in.to_i > 0
      expires_at = DateTime.now + expires_in.to_i.days
    end
  end

  def set_default_name
    if name.blank?
      t = (token || group_token).first(5)
      self.name = "Quicktransfer #{t}"
    end
  end


end
