#!/bin/sh

set -e

echo "Removing the duplicated pidssss ..."
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rails s -b 0.0.0.0
