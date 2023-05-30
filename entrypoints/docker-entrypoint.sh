#!/bin/sh

set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rails s -b 0.0.0.0



# se eu quiser acessa o rails console eu tenho que rodar esse container serparadamente
# docker compose run -d -ti app rails console