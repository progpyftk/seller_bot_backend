# config/initializers/sidekiq_alive.rb
SidekiqAlive.setup do |config|
  config.port = 8080 # escolha uma porta que esteja livre
end
