class Transfer < ActiveRecord::Base

  belongs_to :user
  has_many :folders
  has_many :statistics, class_name: 'TransferStat', order: 'created_at DESC'
  scope :expired, lambda { where('`expires_at` IS NOT NULL AND `expires_at` < ?', DateTime.now) }
  scope :active, lambda { where('`expires_at` IS NULL OR `expires_at` >= ?', DateTime.now) }
  scope :for_user, lambda { |user| user.admin? ? where(true) : where(user_id: user.id) }


  has_attached_file :object,
    path: ':partition/:class/:id/:filename'

  attr_writer :expires_in
  attr_accessor :empty
  attr_accessible :expires_in, :name, :object,
    :recipients, :token, :user_id, :user, :group_token,
    :empty, :done


  #before_validation :compress_files
  before_validation :generate_token, :set_default_name, on: :create
  before_create :setup_exires_at
  after_commit :delete_transfer_files, :send_mail_to_recipients, on: :create
  after_commit :delete_transfer_files, :send_mail_to_recipients, on: :update
  after_commit :async_compress_files, unless: proc {done? or empty}

  validates :token, uniqueness: true
  # validates :name, presence: true
  validates :group_token, presence: true, length: {is: 16}, unless: :done?
  validates :token, presence: true, length: {is: 32}
  validate :valid_recipients
  validates :files, length: {minimum: 1}, unless: proc {done? or empty}
  validates :object, attachment_presence: true, on: :update
  validates :object, attachment_content_type: { content_type: /.*/i }

  def initialize(*args)
    super
    if read_attribute(:group_token).blank?
      write_attribute(:group_token, last_user_group_token)
    end
  end

  alias :tid :id
  def size; object_file_size; end
  def date
    expires_at || (Time.now + 1000.years)
  end

  def expires_in
    if expires_at.present?
      ((expires_at.to_datetime - DateTime.now)/1.day).ceil
    else
      @expires_in || 7
    end
  end

  def saved
    if folders_count > 0
      folders.where(user_id: user.id).first
    end
  end

  def content
    if zip?
      Zip::File.open(object.path) do |f|
        f.entries.map do |entry|
          entry.name.force_encoding('utf-8')
        end
      end
    else
      [object_file_name]
    end
  end

  def last_downloaded_at
    self.statistics.first.created_at
  end

  def zip?
    if object?
      !!object.content_type.match(%r{application/zip})
    else
      make_archive?
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
    TransferFile.loose.where(transfer_files: {user_id: user_id}).first.try(:token) || SecureRandom.hex(8)
  end

  def generate_token
    begin
      self.token = SecureRandom.hex(16)
    end until self.class.where(token: self.token).empty?
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

  def async_compress_files
    TransferArchiveWorker.perform_async(self.token)
  end

  def compress_files
    self.object = create_object_from_transfer
    if self.object_file_name.empty?
      self.object.instance_write :file_name,  file_name_from_title
    end
    @delete_files = true
    self.done = true
    self
  end

  def file_name_from_title(ext = :zip)
    name = self.name.try(:parameterize)
    name = "quicktransfer-#{token || group_token}" if name.blank?
    "#{name}.#{ext}"
  end

  def make_archive?
    !files.one? or files.first.psd?
  end

  def create_object_from_transfer
    if files.one? and !(single_file = files.first).psd?
      return single_file.object
    end

    filename = Dir::Tmpname.make_tmpname("transfer-#{token}", ".zip")
    filepath = File.join(Dir::tmpdir, filename)

    Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
      files.map do |file|
        name = file.name
        ext = File.extname(name)
        basename = File.basename(name, ext)
        it = 1
        while zipfile.find_entry(name)
          name = "#{basename}.#{it}#{ext}"
          it += 1
        end
        zipfile.add(name, file.object.path) { true }
      end
    end

    File.open(filepath)
  end

  def delete_transfer_files
    if @delete_files and done?
      self.files.each(&:destroy)
    end
  end

  def send_mail_to_recipients
    if recipients_list.any? and done?
      TransferMailer.after_create(self).deliver
    end
  end

  def setup_exires_at
    if expires_in.to_i > 0
      self.expires_at = DateTime.now + expires_in.to_i.days
    end
  end

  def set_default_name
    if name.blank? and !make_archive?
      self.name = File.basename(files.first.object_file_name, '.*').titleize
    elsif name.blank?
      t = (token || group_token).first(5)
      self.name = "Quicktransfer #{t}"
    end
  end


end
