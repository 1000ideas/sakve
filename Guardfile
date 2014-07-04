# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'passenger', standalone: false, ping: true, cli: '-a sakve.local.dev -p 80' do
  watch(/^Gemfile/)
  watch(/^lib\/.*\.rb$/)
  watch(/^config\/.*\.rb$/)
end

### Guard::Sidekiq
#  available options:
#  - :verbose
#  - :queue (defaults to "default") can be an array
#  - :concurrency (defaults to 1)
#  - :timeout
#  - :environment (corresponds to RAILS_ENV for the Sidekiq worker)
guard 'sidekiq', :environment => 'development', verbose: true do
  watch(%r{^workers/(.+)\.rb$})
  watch(%r{^models/(.+)\.rb$})
end
