namespace :sakve do
  namespace :transfer do
    desc 'Clean up expired transfers'
    task clean: :environment do
      transfers = Transfer.archive_expired
      cleaned = Transfer.delete_extracted
      puts "Archived #{transfers.length} transfers"
      puts "Cleaned #{cleaned.length} extarcted transfers"
    end

    desc 'Clean up transfers left in a uploads dir due to wrong permissions'
    task cleanup_transfers_folder: :environment do
      path = Rails.root.join('uploads/transfers')
      counter = 0
      Dir.foreach(path) do |item|
        next if item == '.' || item == '..'

        unless Transfer.where(id: item).exists?
          exec `sudo rm -rf #{File.join(path, item)}` rescue puts "Error: #{File.join(path, item)}"
          counter += 1
        end
      end
      puts "Cleaned after #{counter} transfers"
    end
  end
end
