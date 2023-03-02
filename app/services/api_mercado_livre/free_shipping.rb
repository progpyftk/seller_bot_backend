# ML Api
module ApiMercadoLivre
  class FreeShipping < ApplicationService
    def initialize(item)
      @item = item
    end

    def call
      change_free_shipping
      # puts '------ @response do free_Shipping ------'
      # puts  @response
      @response
    end

    def change_free_shipping
      headers = { 'Authorization' => "Bearer #{@item.seller.access_token}",
                  'content-type' => 'application/json',
                  'accept' => 'application/json' }
      url = "https://api.mercadolibre.com/items/#{@item.ml_item_id}"
      payload = { 'shipping' => { 'free_shipping' => false } }.to_json
      # puts '------  ESSE É O PAYLOAD ----------'
      # puts payload
      begin
        @response = RestClient.put(url, payload, headers)
      rescue RestClient::ExceptionWithResponse => e
        @response = e.response
      end
    end
  end
end
