# ML Api
module ApiMercadoLivre
    class FlexTurnOff < ApplicationService
      def initialize(ml_item_id)
        @ml_item_id = ml_item_id
        @response = nil
      end
      
      def call
        turn_off_flex
        @response
      end
  
      def turn_off_flex
        puts 'desligando o flex'
        puts @ml_item_id
        seller = ApiMercadoLivre::FindSellerByItemId.call(@ml_item_id)
        headers = { 'Authorization' => "Bearer #{seller.access_token}",
                    'content-type' => 'application/json',
                    'accept' => 'application/json' }
        url = "https://api.mercadolibre.com/sites/MLB/shipping/selfservice/items/#{@ml_item_id}"
        begin
          @response = RestClient.delete(url, headers)
          @response = @response.code
        rescue RestClient::ExceptionWithResponse => e
          @response = e.http_code
        end
      end
    end
  end
  