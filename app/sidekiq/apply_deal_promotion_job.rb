# populate_tiny_db.rb
class ApplyDealPromotionJob
    include Sidekiq::Worker
  
    def perform(item, seller, promotion_id, promotion_type)
      Rails.logger.info "# Aplicando promoção no - #{item.to_json}"
      if item['status'] == "candidate"
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
          @ativados = @ativados + 1
          Rails.logger.info "Promoção aplicada com sucesso"
          Rails.logger.info "#{response.body.to_json}" 
        else
          @nao_ativados = @nao_ativados + 1
          Rails.logger.error "Erro no momento da ativação"
          Rails.logger.error "#{response.code.to_json}" 
          Rails.logger.error "#{response.body.to_json}" 
        end
      else
        Rails.logger.warn "Item veio em branco, logo não há anúncios aptos para essa campanha: #{promotion_id}  #{promotion_type}"
      end
    end
  end

  end
  