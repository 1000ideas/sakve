class TransferFile < ActiveRecord::Base
  belongs_to :user

  attr_accessible :object, :token, :user_id, :user

  has_attached_file :object,
    path: ':partition/:class/:token/:id/:filename'

  before_create :init_token

  validates :token, length: {is: 16}
  validates :user_id, presence: true
  validates :object,
    attachment_presence: true,
    attachment_content_type: { content_type: /.*/i }

  # Returns tempfile containg zipped files marked with token
  def self.compress(token, debug = false)
    filename = Dir::Tmpname.make_tmpname("transfer-#{token}", ".zip")
    filepath = File.join(Dir::tmpdir, filename)

    Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
      self.where(token: token).map do |file|
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
