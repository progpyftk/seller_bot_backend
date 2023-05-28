# ML Api
module ApiMercadoLivre
  # retorna a chamada de um anuncio
  class ItemGeneralData < ApplicationService

    def initialize(item)
      @item = item
      @seller = nil
      @response = nil
    end

    def call
      search_item
      @response
    end

    def search_item
      @seller = ApiMercadoLivre::FindSellerByItemId.call(@item) 
      url = "https://api.mercadolibre.com/items/#{@item}?include_attributes=all"
      @response = RestClient.get(url, auth_header)
    end

    def auth_header
      ApiMercadoLivre::AuthenticationService.call(@seller)
      { 'Authorization' => "Bearer #{@seller.access_token}" }
    end
  end
end