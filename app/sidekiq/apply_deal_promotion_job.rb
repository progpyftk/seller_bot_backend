class ApplyDealPromotionJob
  include Sidekiq::Worker

# meu proximo desafio é saber quando terminou de fazer, e provavelmente isso será feito por meio da Redis
# no chatgpt tem uma pergunta qeu fiz sobre isso
=begin
Você pode usar o Redis para manter um contador ou uma flag que indica quantos jobs foram processados. 
A ideia é incrementar esse contador toda vez que um job é concluído e verificar periodicamente se o número 
total de jobs processados é igual ao número total de jobs que foram enfileirados.
=end


  def perform(item, ml_seller_id, promotion_id, promotion_type)
    seller = Seller.find(ml_seller_id)
    Rails.logger.info "--- ApplyDealPromotionJob: INICIANDO JOB NO SIDEKIQ -----"
    
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
        return true
      else
        Rails.logger.error "Problema na ativação do anúncio"
        return false
      end
    else
      Rails.logger.info "Item veio em branco, logo não há anúncios aptos para essa campanha: #{promotion_id} #{promotion_type}"
    end
  end
end
