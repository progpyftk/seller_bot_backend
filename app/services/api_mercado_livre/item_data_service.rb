require 'rest-client'
require 'json'
require 'pp'

# ML Api
module ApiMercadoLivre
  # retorna a chamada de um anuncio
  class ItemDataService < ApplicationService
    attr_accessor :item

    def initialize(ml_item_id, seller)
      @ml_item_id = ml_item_id
      @seller = seller
    end

    def call
      search_item
    end

    def search_item
      url = "https://api.mercadolibre.com/items/#{@ml_item_id}/variations"
      JSON.parse(RestClient.get(url, auth_header))
    end

    def auth_header
      ApiMercadoLivre::AuthenticationService.call(@seller)
      { 'Authorization' => "Bearer #{@seller.access_token}" }
    end
  end
end
