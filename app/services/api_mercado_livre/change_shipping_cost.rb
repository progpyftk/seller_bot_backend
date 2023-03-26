# ML Api
module ApiMercadoLivre
    class ChangeShippingCost < ApplicationService
      def initialize(ml_item_id)
        @item = ml_item_id
        @seller = ApiMercadoLivre::FindSellerByItemId.call(ml_item_id)
  
      def call
        change_shipping_cost
        @response
      end
  
      def change_free_shipping
        headers = { 'Authorization' => "Bearer #{@seller.access_token}",
                    'content-type' => 'application/json',
                    'accept' => 'application/json' }
        url = "https://api.mercadolibre.com/items/#{@item}"
        payload = { 'shipping' => { 'free_shipping' => false } }.to_json
        begin
          @response = RestClient.put(url, payload, headers)
          pp @response
        rescue RestClient::ExceptionWithResponse => e
          @response = e.response
          puts e.response
        end
      end
    end
  end