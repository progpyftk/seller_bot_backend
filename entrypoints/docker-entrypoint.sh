#!/bin/sh

set -e

echo "Removing the duplicated pids ..."
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "exec rails db:create ..."
bundle exec rails db:create
echo "exec rails db:migrate ..."
bundle exec rails db:migrate
echo "Starting app server ..."
bundle exec rails s -b 0.0.0.0
