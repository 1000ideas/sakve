class Transfer < ActiveRecord::Base
  EXPIRES_IN_DAYS = 7

  belongs_to :user
  scope :expired, lambda { where('`expires_at` < ?', DateTime.now) }
  scope :active, lambda { where('`expires_at` >= ?', DateTime.now) }
  scope :for_user, lambda { |user| user.admin? ? where(true) : where(user_id: user.id) }


  has_attached_file :object,
    path: ':partition/:class/:id/:filename'
    
  attr_accessible :expires_at, :name, :object, :recipients, :token, :user_id, :user, :group_token

  attr_writer :group_token

  #before_validation :compress_files
  after_create :generate_token, :delete_transfer_files, :set_expires_at, :send_mail_to_recipients

  validates :token, uniqueness: true
  validates :name, presence: true
  validates :group_token, presence: true, length: {is: 16}
  validate :valid_recipients
  validates :files, length: {minimum: 1}, if: Proc.new { |a| a.token.blank? }
  validates :object, attachment_presence: true

  def group_token
    @group_token ||= last_user_group_token || SecureRandom.hex(8)
  end

  def group_token=(value)
    @group_token = value
    compress_files
    group_token
  end

  def files
    TransferFile.where(token: group_token)
  end

  def self.delete_expired
    self.expired.each(&:destroy)
  end

  def recipients_list
    recipients.split(',').map(&:strip).sort
  end

  def expired?
    expires_at < DateTime.now
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
    self.recipients.split(',').map(&:strip).each do |email|
      recipient_count += 1
      unless email.match /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        self.errors.add(:recipients, :invalid)
        break
      end
    end
    self.errors.add(:recipients, :too_short, count: 1) unless recipient_count > 0
  end

  def compress_files
    if group_token && ! self.object?
      self.object = TransferFile.compress(group_token)
      self.object.instance_write :file_name,  file_name_from_title
      @delete_files = true
    end
  end

  def file_name_from_title(ext = :zip)
    name = self.name.parameterize
    name = "#{token || group_token}-#{Time.now.to_i}" if name.blank?
    "#{name}.#{ext}"
  end

  def delete_transfer_files
    self.files.each(&:destroy) if @delete_files
  end

  def set_expires_at
    update_attributes(expires_at: DateTime.now + EXPIRES_IN_DAYS.days)
  end

  def send_mail_to_recipients
    TransferMailer.after_create(self).deliver
  end


end
