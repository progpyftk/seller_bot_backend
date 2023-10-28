module ApiMercadoLivre
  class PromotionItemsCheck < ApplicationService
    def initialize(seller, promotion_id, promotion_type)
      @promotion_id = promotion_id
      @promotion_type = promotion_type
      @seller = seller
    end

    def call
      fetch_items_promotion
    end

    private

    def fetch_items_promotion
      url = "https://api.mercadolibre.com/seller-promotions/promotions/#{@promotion_id}/items?promotion_type=#{@promotion_type}&status=candidate&app_version=v2"
      headers = {
        'Authorization' => "Bearer #{@seller.access_token}",
        'Content-Type' => 'application/json'
      }
      response = HTTParty.get(url, headers: headers)
      handle_response(response)
      if response['results'].nil?
        return false
      else
        return true
      end
    end

    def handle_response(response)
      if response.success?
        log_successful_call
    
      else
        log_error_call(response)
      end
    end

    def log_successful_call
      puts 'Chamada bem-sucedida!'
    end

    def log_error_call(response)
      puts '  PromotionItemsService: Erro na chamada dos itens de promoção do vendedor  '
      puts "  Código de erro: #{response.code}"
      puts "  Corpo da resposta: #{response.body}"
    end
  end
end
