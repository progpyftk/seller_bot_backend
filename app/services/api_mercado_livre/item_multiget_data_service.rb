require 'rest-client'
require 'json'
require 'pp'

# ML Api
module ApiMercadoLivre
  # pega os dados de um anuncio especifico de um seller
  class ItemMultigetDataService < ApplicationService
    attr_accessor :item

    def initialize(all_items_ids_array, seller)
      @all_items_ids_array = all_items_ids_array
      @seller = seller
    end

    def call
      multiget_items
    end

    # Utiliza a função Multiget para melhorar a interação com os recursos 
    # de itens e users e poder acessar assim um máximo de 20 resultados com uma única chamada. 
    def multiget_items
      resp = []
      urls_list.each do |url|
         # aqui faz uma chamada para 20 anuncios de uma única vez, e vai concatenando 
         # até formar um array com os dados de todos os anuncios
        resp.concat(JSON.parse(RestClient.get(url, auth_header)))
      end
      resp # a list of hashes
    end

    # cria uma lista com as urls de 20 em 20 anuncios até retornar uma lista com elas
    def urls_list
      url_list = []
      @all_items_ids_array.each_slice(20) do |batch|
        url = 'https://api.mercadolibre.com/items?ids='
        batch.each do |item_id|
          url.concat("#{item_id},")
        end
        url_list.push(url[0..-2])
      end
      url_list
    end

    def auth_header
      #ApiMercadoLivre::AuthenticationService.call(@seller)
      { 'Authorization' => "Bearer #{@seller.access_token}" }
    end
  end
end

