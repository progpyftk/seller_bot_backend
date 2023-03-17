# ML Api
module ApiMercadoLivre
  # retorna a chamada de um anuncio
  class ItemGeneralData < ApplicationService

    def initialize(item)
      @item = item.ml_item_id
      @seller = item.seller
      @response = nil
    end

    def call
      search_item
      @response
    end

    def search_item
      url = "https://api.mercadolibre.com/items/#{@item}"
      @response = (RestClient.get(url, auth_header))
      puts '--------Response Original --------------'
      pp @response
    end

    def auth_header
      ApiMercadoLivre::AuthenticationService.call(@seller)
      { 'Authorization' => "Bearer #{@seller.access_token}" }
    end
  end
end
