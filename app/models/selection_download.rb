class SelectionDownload < ActiveRecord::Base
  self.primary_key = :id
  attr_accessor :prevent_async_create
  attr_accessible :user_id, :ids, :fids, :prevent_async_create

  serialize :ids, JSON
  serialize :fids, JSON
  belongs_to :user

  before_create :generate_id
  after_commit :async_create_archive, on: :create, unless: :prevent_async_create

  def self.check_dir_existance(dir)
    unless File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end
  end

  def path
    Rails.root.join('selection-zips', "#{self.id}.zip")
  end

  def async_create_archive
    SelectionArchiveWorker.perform_async(self.id)
  end

  def file
    if done?
      path.open
    end
  end

  def create_archive
    self.class.check_dir_existance(path.dirname)
    Zip::File.open(path, Zip::File::CREATE) do |zipfile|
      folders.each do |folder|
        folder.each_descendant do |f|
          path = f.ancestors_until(folder.parent, true).map(&:name).reverse.join('/')
          unless path.blank?
            zipfile.mkdir(path) unless zipfile.find_entry(path)
            Rails.logger.debug "[zip mkdir] #{path}"
            path += '/'
          end
          f.items.each do |item|
            Rails.logger.debug "[zip add] #{path}#{item.name_for_download}"
            zipfile.add("#{path}#{item.name_for_download}", item.object.path) { true }
          end
        end
      end
      items.each do |item|
        Rails.logger.debug "[zip add] #{item.name_for_download}"
        zipfile.add("#{item.name_for_download}", item.object.path) { true }
      end
    end
    self.update_column(:done, true)
  end

  def folders
    Folder.where(id: fids)
  end

  def items
    Item.where(id: ids)
  end

  private

  def file_for_transfer
    create_archive unless done?
    file
  end

  def generate_id
    self.id = SecureRandom.hex(16) until self.class.where(id: self.id).empty?
  end
end
