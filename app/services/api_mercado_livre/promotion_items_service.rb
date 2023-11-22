module ApiMercadoLivre
  class PromotionItemsService < ApplicationService
    def initialize(seller, promotion_id, promotion_type, offset_limit = 1000)
      @promotion_id = promotion_id
      @promotion_type = promotion_type
      @seller = seller
      @all_items = []
      @offset_limit = offset_limit
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

      offset = 50
      while response['results'].present? && response['results'].length >= 50 do
        url = "https://api.mercadolibre.com/seller-promotions/promotions/#{@promotion_id}/items?promotion_type=#{@promotion_type}&offset=#{offset}&status=candidate&app_version=v2"
        response = HTTParty.get(url, headers: headers)
        handle_response(response)
        offset += 50
        if offset > @offset_limit
          break
        end
      end
      @all_items
    end

    def handle_response(response)
      if response.success?
        log_successful_call
        @all_items.push(*response['results'])
      else
        log_error_call(response)
      end
      response
    end

    def log_successful_call

      puts 'promotion_items_service - Chamada bem-sucedida!'
    end

    def log_error_call(response)
      puts '  PromotionItemsService: Erro na chamada dos itens de promoção do vendedor  '
      puts "  Código de erro: #{response.code}"
      puts "  Corpo da resposta: #{response.body}"
    end
  end
end
