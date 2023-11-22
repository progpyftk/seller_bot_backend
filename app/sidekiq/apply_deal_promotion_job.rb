class ApplyDealPromotionJob
  include Sidekiq::Worker
  sidekiq_options retry: false
  sidekiq_options queue: :default  # Use a default or priority-based queue

  def perform(item, ml_seller_id, promotion_id, promotion_type)
    seller = Seller.find(ml_seller_id)
    channel_key = "#{promotion_id}_#{ml_seller_id}"

    Rails.logger.info "--- ApplyDealPromotionJob: Starting job for promotion #{promotion_id} ---"

    if item['status'] == "candidate"
      Rails.logger.info "Aplicando promoção"
      item_id = item['id']
      deal_price = item['original_price'].to_f * 0.95
      url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"
      headers = {
        'Authorization' => "Bearer #{seller.access_token}",
        'Content-Type' => 'application/json'
      }
      body = {
        "promotion_id" => promotion_id,
        "promotion_type" => promotion_type,
        "deal_price" => deal_price.round(0),
      }.to_json

      response = HTTParty.post(url, headers: headers, body: body)

      if response.success?
        Rails.logger.info "Anúncio ativado com sucesso"
      else
        Rails.logger.error "Problema na ativação do anúncio: #{response.body}"
      end
    else
      Rails.logger.info "Item veio em branco, logo não há anúncios aptos para essa campanha: #{promotion_id} #{promotion_type}"
    end

  ensure
    # Decrement the job counter for the promotion after job is done or fails
    PromotionJobTracker.job_completed(channel_key)
    puts " ******* #{channel_key} ******** "
    ActionCable.server.broadcast(
      "promotion_notification:#{channel_key}", # a channel_key é a combinação de promotion_id e ml_seller_id
      { status: 'aplicando promoções'}
    )
  end

end
