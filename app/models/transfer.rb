class Transfer < ActiveRecord::Base

  belongs_to :user
  has_many :folders
  has_many :statistics, class_name: 'TransferStat', order: 'created_at DESC'
  scope :expired, lambda { where('`expires_at` IS NOT NULL AND `expires_at` < ?', DateTime.now) }
  scope :active, lambda { where('`expires_at` IS NULL OR `expires_at` >= ?', DateTime.now) }
  scope :for_user, lambda { |user| user.admin? ? where(true) : where(user_id: user.id) }
  scope :extracted, where(extracted: true)

  has_attached_file :object,
    path: ':partition/:class/:id/:filename'

  attr_writer :expires_in
  attr_accessor :empty, :expires_in_infinity
  attr_accessible :expires_in, :name, :object, :recipients, :token,
                  :user_id, :user, :group_token, :empty, :done,
                  :expires_in_infinity, :message, :expired, :infos_hash

  serialize :infos_hash, Hash

  #before_validation :compress_files
  before_validation :generate_token, :set_default_name, on: :create
  before_validation :setup_exires_at
  after_commit :delete_transfer_files, :send_mail_to_recipients, only: [:create, :update]
  # after_commit :delete_transfer_files, :send_mail_to_recipients, on: :update
  after_commit :check_infos_hash, on: :create
  after_commit :async_compress_files, unless: proc {done? or empty}

  validates :token, uniqueness: true
  # validates :name, presence: true
  validates :group_token, presence: true, length: {is: 16}, unless: :done?
  validates :token, presence: true, length: {minimum: 10, maximum: 64}
  validate :valid_recipients
  validates :files, length: {minimum: 1}, unless: proc {done? or empty}
  validates :object, attachment_presence: true, on: :update
  validates :object, attachment_content_type: { content_type: /.*/i }

  alias :tid :id

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
    @expires_in || if expires_at.present?
      ((expires_at - Time.now)/1.day).ceil
    else
      7
    end
  end

  def saved
    if folders_count > 0
      folders.where(user_id: user.id).first
    end
  end

  def content
    self.infos_hash
  end

  def zip_content
    if !self.expired? and self.infos_hash[:files][0].nil?
      self.infos_hash[:files].drop(1)
    else
      self.infos_hash[:files]
    end
  end

  def last_downloaded_at
    self.statistics.first.try(:created_at)
  end

  def zip?
    if object?
      !!object.content_type.match(%r{application/zip}) &&
        !object_file_name.ends_with?('.fla')
    else
      make_archive?
    end
  end

  def files
    TransferFile.where(token: group_token)
  end

  def self.archive_expired
    expired.each(&:archive)
  end

  def self.delete_extracted
    extracted.each(&:clean_extracted_files)
  end

  def self.delete_expired
    expired.each(&:destroy)
  end

  def recipients_list
    if recipients.kind_of?(String)
      recipients.split(/[,\s]+/).sort
    else
      []
    end
  end

  def forever?
    persisted? and expires_at.nil?
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

  def archive
    self.expired = true
    self.object.destroy
  end

  def archived?
    self.expired
  end

  def generate_infos_hash
    info_hash = Hash.new
    info_hash[:name] = self.object_file_name
    info_hash[:size] = self.object_file_size
    info_hash[:type] = self.object_content_type
    if self.object.path and self.zip?
      info_hash[:files] = Array.new
      i = 1
      Zip::File.open(self.object.path) do |f|
        f.entries.each do |entry|
          info_hash[:files][i] = Hash.new
          info_hash[:files][i][:name] = entry.name.encode('UTF-8', :invalid => :replace, :undef => :replace)
          info_hash[:files][i][:size] = entry.size
          i = i + 1
        end
      end
    end
    self.infos_hash = info_hash
    self.save
  end

  def check_infos_hash
    if self.done? and self.infos_hash == {} and self.object.exists?
      self.generate_infos_hash
    end
  end

  def download_name
    if self.zip?
      name = "Sakve #{self.created_at_formatted}.zip"
    else
      name = self.object_file_name
    end
  end

  def created_at_formatted
    self.created_at.strftime('%d-%m-%Y, %H:%M:%S')
  end

  def directory
    object.path.rpartition('/').first(2).join
  end

  def extract(name)
    return false unless zip?
    Zip::File.open(object.path) do |zipfile|
      file = zipfile.find { |f| f.name == name }
      file.extract(directory + file.name)
    end
    update_attribute(:extracted, true)
  end

  def include?(filename)
    if zip? && file_in_zip?(filename)
      true
    else
      false
    end
  end

  def clean_extracted_files
    return false unless zip?
    Dir.foreach(directory) do |item|
      next if item.ends_with?('.zip') || item == '.' || item == '..'
      File.delete(directory + item)
    end
    update_attribute(:extracted, false)
  end

  private

  def file_in_zip?(filename)
    Zip::File.open(object.path) do |zipfile|
      return zipfile.any? { |f| f.name == filename }
    end
  end

  def last_user_group_token
    TransferFile.loose.where(transfer_files: {user_id: user_id}).first.try(:token) || SecureRandom.hex(8)
  end

  def generate_token
    begin
      self.token = SecureRandom.hex(5)
    end until self.class.where(token: self.token).empty?
  end

  def valid_recipients
    recipient_count = 0
    self.recipients.try(:split, /[,\s]+/).try(:each) do |email|
      recipient_count += 1
      unless email.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)
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
    @delete_files = true
    self.done = true
    self
  end

  def file_name_from_title(ext = :zip)
    name = self.name.try(:parameterize)
    name = "Sakve quicktransfer #{self.created_at.strftime('%d-%m-%Y, %H:%M:%S')}" if name.blank?
    "#{name}.#{ext}"
  end

  def make_archive?
    content[:files] && (!files.one? || files.first.psd?)
  end

  def create_object_from_transfer
    if files.uploaded.one? && !(single_file = files.uploaded.first).psd?
      return single_file.object
    end

    filename = Dir::Tmpname.make_tmpname("Sakve #{self.created_at.strftime('%d-%m-%Y, %H:%M:%S')}", ".zip")
    filepath = File.join(Dir::tmpdir, filename)

    logger.debug "Zipping files...."

    Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
      files.uploaded.map do |file|
        name = file.name
        ext = File.extname(name)
        basename = File.basename(name, ext)
        it = 1
        while zipfile.find_entry(name)
          name = "#{basename}.#{it}#{ext}"
          it += 1
        end
        logger.debug "File: #{name}..."
        zipfile.add(name, file.object.path) { true }
        logger.debug "File: #{name}...done"
      end
    end

    self.object.instance_write :file_name, filename
    logger.debug "Zipping files....done"

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
    if @expires_in_infinity.to_i == 1
      self.expires_at = nil
    elsif expires_in.to_i > 0
      self.expires_at = DateTime.now + expires_in.to_i.days
    end
  end

  def set_default_name
    if name.blank? and !make_archive?
      self.name = File.basename(files.first.object_file_name, '.*').titleize
    elsif name.blank?
      t = (token || group_token).first(5)
      self.name = "Sakve #{Time.now.strftime('%d-%m-%Y, %H:%M:%S')}"
    end
  end
end
