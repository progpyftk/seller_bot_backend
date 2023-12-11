#!/bin/bash
set -e

# Cria os diretórios necessários se não existirem
mkdir -p tmp/pids


# Remove um arquivo de PID existente do Sidekiq, se houver
if [ -f tmp/pids/sidekiq.pid ]; then
  echo "Removendo PID antigo do Sidekiq..."
  rm tmp/pids/sidekiq.pid
fi

# Remove um arquivo de PID existente do Puma (Rails), se houver
if [ -f tmp/pids/server.pid ]; then
  echo "Removendo PID antigo do Rails (Puma)..."
  rm tmp/pids/server.pid
fi

# Checa se a variável de ambiente START_SIDEKIQ está definida
if [ "$START_SIDEKIQ" == "true" ]; then
  echo "Iniciando Sidekiq..."
  bundle exec sidekiq -C config/sidekiq.yml
else
  echo "Iniciando Aplicativo Rails..."
  bundle exec puma -C config/puma.rb
fi
