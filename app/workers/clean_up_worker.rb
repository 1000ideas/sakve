class CleanUpWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence do
    if Rails.env.production?
      daily.hour_of_day(3)
    else
      minutely#hourly.minute_of_hour(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)
    end
  end

  def perform
    puts 'Start: Cleaning up temporary files'
    transfers = Transfer.archive_expired
    cleaned = Transfer.delete_extracted
    puts "Archived #{transfers.length} transfers"
    puts "Cleaned #{cleaned.length} extracted transfers"

    path = Rails.root.join('upload_tmp')
    counter = 0
    Dir.foreach(path) do |item|
      next if item == '.' || item == '..'
      next if File.mtime(path.join(item)) > Time.now - Sakve::Application.config.delete_tmp_after.days

      unless Transfer.where(id: item).exists?
        `rm -rf #{File.join(path, item)}` rescue puts "Error: #{File.join(path, item)}"
        counter += 1
      end
    end

    puts "Cleaned #{counter} temp files"
    puts 'End: Cleaning up temporary files'

    puts 'Start: Cleaning up files left in upload directory due to wrong permissions'
    path = Rails.root.join('uploads/transfers')
    counter = 0
    Dir.foreach(path) do |item|
      next if item == '.' || item == '..'

      unless Transfer.where(id: item).exists?
        `sudo rm -rf #{File.join(path, item)}` rescue puts "Error: #{File.join(path, item)}"
        counter += 1
      end
    end
    puts "Cleaned after #{counter} transfers"
    puts 'End: Cleaning up files left in upload directory due to wrong permissions'
  end
end
