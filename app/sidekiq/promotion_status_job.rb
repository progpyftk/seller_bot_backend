class PromotionStatusJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  # Constante para as classes de jobs a serem verificadas
  JOB_CLASSES = [
    'ApplyDealPromotionJob',
    'ApplyLightningPromotionJob',
    'ApplyMarketplacecampaingPromotionJob'
  ].freeze

  def perform
    puts "+++++++ Checking promotion status ++++++"

    # Verifica se há jobs enfileirados nas classes especificadas
    jobs_count = count_promotion_jobs

    # Define o canal de transmissão
    channel_key = "promotion_status"

   # Transmite o status baseado na contagem de jobs
   # ActionCable.server.broadcast(
   #   "promotion_status_channel:#{channel_key}",
   #   { status: jobs_count.positive? ? "processing" : "completed" }
   # )
    puts "Channel Key: #{channel_key}, Jobs Count: #{jobs_count}"

    return jobs_count
  end

  private

  # Conta o número de jobs enfileirados nas classes especificadas
  def count_promotion_jobs
    Sidekiq::Queue.all.sum do |queue|
      queue.count { |job| JOB_CLASSES.include?(job['class']) }
    end
  end
end
