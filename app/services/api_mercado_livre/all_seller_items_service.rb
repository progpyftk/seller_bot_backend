,require 'rest-client'
require 'json'

# ML Api
module ApiMercadoLivre
  # retornar uma lista com todos os anuncios do vendedors, apenas os ids
  class AllSellerItemsService < ApplicationService
    attr_accessor :seller

    def initialize(seller)
      @seller = seller
      @items = []
    end

    def call
      all_items
    end

    # cria a lista de todos os anuncios do seller - apenas os ids dos anuncios
    def all_items
      puts 'autenticando um seller'
      ApiMercadoLivre::AuthenticationService.call(@seller)
      auth_header = { 'Authorization' => "Bearer #{@seller.access_token}" }
      url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&limit=100"
      resp = JSON.parse(RestClient.get(url, auth_header))
      @items = resp['results']
      url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&scroll_id=#{resp['scroll_id']}&limit=100"
      until resp['results'].empty?
        resp = JSON.parse(RestClient.get(url, auth_header))
        @items.concat(resp['results'])
      end
      @items
    end
  end
end
