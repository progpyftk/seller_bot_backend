# ML Api
module ApiMercadoLivre
    class ChangeFreeShipping < ApplicationService
      def initialize(seller, item)
        @item = item
        @seller = seller
      end
  
      def call
        change_free_shipping
      end
  
      def change_free_shipping
        url = "https://api.mercadolibre.com/items/#{@item}"
        headers = {
            'Authorization' => "Bearer #{@seller.access_token}",
            'Content-Type' => 'application/json'
        }
        body = {
            "shipping" => {'free_shipping' => false }
          }.to_json
        # Fazendo a chamada HTTP POST
        response = HTTParty.put(url, headers: headers, body: body)
    end
    end
  end