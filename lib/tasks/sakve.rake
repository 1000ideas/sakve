namespace :sakve do
  namespace :transfer do
    desc "Clean up expired transfers"
    task clean: :environment do
      transfers = Transfer.delete_expired
      puts "Destroyed #{transfers.length} transfers"
    end
  end
end
