class ApplyLightningPromotionJob
  include Sidekiq::Worker
  sidekiq_options retry: false
  sidekiq_options queue: :default  # Use a default or priority-based queue

  def perform(item, ml_seller_id, promotion_id, promotion_type)
    seller = Seller.find(ml_seller_id)
    channel_key = "#{promotion_id}_#{ml_seller_id}"

    Rails.logger.info "--- ApplyLightningPromotionJob: Starting job for promotion #{promotion_id} ---"

    if item['status'] == "candidate"
      Rails.logger.info "Aplicando promoção"
      item_id = item['id']
      stock = item['stock']['min'] # por padrão vamos usara o estoque mínimo
      # coloquei o final XX.88 para saber as que foram por conta do lightning
      deal_price = (item['original_price']*0.94).round(0) - 0.12
      url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"
      headers = {
        'Authorization' => "Bearer #{seller.access_token}",
        'Content-Type' => 'application/json'
      }
      body = {
        "deal_price" => deal_price,
        "stock" => stock,
        "promotion_type" => promotion_type,
      }.to_json
      response = HTTParty.post(url, headers: headers, body: body)
      if response.success?
        Rails.logger.info "Promoção aplicada com sucesso"
        Rails.logger.info "#{response.code.to_json}"
        Rails.logger.info "#{response.body.to_json}"
      else
        Rails.logger.info "#{body}"
        Rails.logger.info "Erro na ativação da promoção lightning"
        Rails.logger.info "#{response.code.to_json}"
        Rails.logger.info "#{response.body.to_json}"
      end
    else
      Rails.logger.info "Item veio em branco, logo não há anúncios aptos para essa campanha: #{promotion_id} #{promotion_type}"
    end

  ensure
    ActionCable.server.broadcast(
      "promotion_notification:#{channel_key}", # a channel_key é a combinação de promotion_id e ml_seller_id
      { status: 'processing_promotions'}
    )
    # Decrement the job counter for the promotion after job is done or fails
    PromotionJobTracker.job_completed(channel_key)
  end

end
