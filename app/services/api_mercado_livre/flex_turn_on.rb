# ML Api
module ApiMercadoLivre
    class FlexTurnOn < ApplicationService
      def initialize(item)
        @item = item
        @response = true
      end
      
      def call
        check_flex
        @response
      end
  
      def check_flex
        headers = { 'Authorization' => "Bearer #{@item.seller.access_token}",
                    'content-type' => 'application/json',
                    'accept' => 'application/json' }
        url = "https://api.mercadolibre.com/sites/MLB/shipping/selfservice/items/#{@item.ml_item_id}"
        
        begin
          @response = RestClient.put(url, headers)
          @response = @response.code
        rescue RestClient::ExceptionWithResponse => e
          @response = e.http_code
        end
      end
    end
  end
  