#!/bin/bash

echo "Creating database"
rake db:create

echo "Migrating database"
rake db:migrate

echo "Starting server"
rm -f /sakve/tmp/pids/server.pid
bundle exec rails s -p 3000 -b '0.0.0.0'
