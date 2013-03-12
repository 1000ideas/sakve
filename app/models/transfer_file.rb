class TransferFile < ActiveRecord::Base
  #Path to zip executable
  mattr_accessor :zip_path
  @@zip_path = '/usr/bin/zip'

  belongs_to :user

  attr_accessible :object, :token, :user_id, :user

  has_attached_file :object,
    path: ':partition/:class/:token/:id_:filename'

  before_create :init_token

  validates :token, length: {is: 16}
  validates :user_id, presence: true
  validates :object, attachment_presence: true

  # Returns tempfile containg zipped files marked with token
  def self.compress(token, debug = false)
    file = Tempfile.new([token, '.zip'])
    files = self.where(token: token).map do |file|
      file.object.path.try(:shellescape)
    end.compact

    command = "#{self.zip_path} -D -9 -j - #{files.join(' ')} > #{file.path.shellescape}"
    Rails.logger.debug "[compress] Command: #{command}" if debug
    system(command)
    file
  end

  alias_attribute :name, :object_file_name

  def self.setup
    yield self
  end

  private

  def init_token
    if token.blank?
      ntoken = SecureRandom.hex(8) until self.class.where(token: ntoken) == 0
      self.update_attributes(token: ntoken)
    end
  end
end
