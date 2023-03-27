# ML Api
module ApiMercadoLivre
    class FreeShipping < ApplicationService
      def initialize(seller)
        @seller = seller
      end
  
      def call
        free_shipping
        []
      end
  
      def free_shipping    
        ApiMercadoLivre::AuthenticationService.call(@seller)
        headers = { 'Authorization' => "Bearer #{@seller.access_token}",
        'content-type' => 'application/json',
        'accept' => 'application/json' }
        url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&limit=100&status=active&free_shipping=true"
        response = JSON.parse(RestClient.get(url, headers))
        response['results'].each do |item|
            url =  "https://api.mercadolibre.com/items/#{item}/shipping_options/free"
            puts url
            response = JSON.parse(RestClient.get(url, headers))
            pp response
        end
        Rails.logger.info (response)
      end

    end
  end