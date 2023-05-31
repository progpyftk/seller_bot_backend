class HardJob
  include Sidekiq::Job

  def perform(webhook)
    puts '---- job do sidekiq rodando ----'
    pp webhook
  end
end
