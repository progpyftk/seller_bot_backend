class IncrementCounter
    include Sidekiq::Job
  
    def perform()
      puts 'estou usando o sidekiq'
    end
  end