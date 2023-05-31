class HardJob
  include Sidekiq::Job

  def perform(name, count)
    puts 'FINALMENTE RODANDO O SIDEKIQ'
    puts name
    puts count
  end
end
