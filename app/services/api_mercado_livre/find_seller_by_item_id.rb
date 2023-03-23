# ML Api
module ApiMercadoLivre
    # retorna a chamada de um anuncio
    class FindSellerByItemId < ApplicationService
  
      def initialize(item_id)
        @item_id = item_id
        @response = nil
      end
  
      def call
        find_seller
      end
  
      def find_seller
        Seller.all.each do |seller|
          url = "https://api.mercadolibre.com/items?ids=#{@item_id}&attributes=seller_id"
          @response = RestClient.get(url, auth_header(seller))
          parsed_item = JSON.parse(@response)
          if not parsed_item[0]["body"]["seller_id"].blank?
            seller = Seller.find_by(ml_seller_id: parsed_item[0]["body"]["seller_id"].to_s)
            return seller
          end
        end
        nil
      end
  
      def auth_header(seller)
        # ApiMercadoLivre::AuthenticationService.call(seller)
        { 'Authorization' => "Bearer #{seller.access_token}" }
      end
    end
  end
  