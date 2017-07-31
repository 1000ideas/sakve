namespace :sakve do
  namespace :transfer do
    desc 'Clean up expired transfers and transfers left in a uploads dir due to wrong permissions'
    task clean: :environment do
      CleanUpWorker.perform_async
    end
  end

  namespace :backgrounds do
    desc 'Add old backgrounds to db'
    task add_old: :environment do
      (1..7).each do |i|
        bg = Background.new(
          image: File.new("app/assets/images/transfer/cover-#{i}.jpg", 'r'),
          upload: true,
          download: true,
          link: nil
        )

        if bg.save
          puts "Pomyślnie dodano cover-#{i}"
        else
          puts "Wystąpił błąd podczas dodawania cover-#{i}"
        end
      end
    end
  end
end
