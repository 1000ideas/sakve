#!/bin/bash

echo "Creating database"
rake db:create

echo "Migrating database"
rake db:migrate

if [ $(echo $RAILS_ENV) != "production" ]; then
  echo "Seeding database"
  rake db:seed
else
  rake assets:clean
  rake assets:precompile
fi

echo "Starting sidekiq"
rm -f /sakve/tmp/pids/sidekiq.pid
bundle exec sidekiq -C config/sidekiq.yml

echo "Starting server in" $RAILS_ENV "mode"
rm -f /sakve/tmp/pids/server.pid
bundle exec rails s -p 3000 -b '0.0.0.0'
