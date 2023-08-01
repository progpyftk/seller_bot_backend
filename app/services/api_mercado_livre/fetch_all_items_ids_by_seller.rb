# ML Api
module ApiMercadoLivre
  # baixa e atualiza todos os items de cada vendedor cadastrado no app
  class FetchAllItemsIdsBySeller < ApplicationService
    def initialize(seller)
      @seller = seller
      @items = []
    end

    def call
      fetch_all_items_ids
      @items
    end

    # cria a lista de todos os anuncios do seller - apenas os ids dos anuncios
    def fetch_all_items_ids
      ApiMercadoLivre::AuthenticationService.call(@seller)
      auth_header = { 'Authorization' => "Bearer #{@seller.access_token}" }
      url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&limit=100"
      resp = JSON.parse(RestClient.get(url, auth_header))
      # pode ser que não tenha nenhum anuncio no full sem estoque, então temos que tratar o resp['results']
      @items = resp['results']
      url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&scroll_id=#{resp['scroll_id']}&limit=100"
      until resp['results'].empty?
        resp = JSON.parse(RestClient.get(url, auth_header))
        puts resp
        @items.push(*resp['results'])
      end
      @items
    end
  end
end
