require 'rest-client'
require 'json'
require 'pp'

# ML Api
module ApiMercadoLivre
  # para alterar a quantidade precisamos verificar se o anuncio possui variacoes
  # se nao possuir utilizamos o payload apenas com o id do anuncio
  # caso tenha, utilizamos os ids das ou da variacao, com um payload diferente
  # entao precisamos checar antes de alterar. Note que nao podemos colocar dois valores diferentes,
  # nosso unico objetivo eh reviver o anuncio
  class ChangeAvailableQuantity < ApplicationService
    def initialize(item, new_quantity)
      @item = item
      @new_quantity = new_quantity.to_i
      @response = nil
    end

    def call
      change_quantity
      @response
    end

    # checa se o anuncio tem variacoes, se tiver retorna os ids que serao atualizados com a msm qtt
    def variations_ids
      headers = { 'Authorization' => "Bearer #{@item.seller.access_token}",
                  'content-type' => 'application/json',
                  'accept' => 'application/json' }
      url = "https://api.mercadolibre.com/items/#{@item.ml_item_id}/variations"
      resp = JSON.parse(RestClient.get(url, headers))
      variations = []
      if resp.empty?
        nil
      else
        resp.each do |variation|
          variations << variation['id']
        end
        variations
      end
    end

    # tive que fazer modificacoes importantes para poder lidar com as variacoes
    # no nosso app nao eh possivel alterar a quantidade de uma variacao separadamente, apenas de todo anuncio
    def change_quantity
      headers = { 'Authorization' => "Bearer #{@item.seller.access_token}",
                  'content-type' => 'application/json',
                  'accept' => 'application/json' }
      url = "https://api.mercadolibre.com/items/#{@item.ml_item_id}"
      ids = variations_ids
      if ids
        ids.each do |id|
          payload = { 'variations' => [{ 'id' => id, 'available_quantity' => @new_quantity }]}.to_json
          begin
            @response = RestClient.put(url, payload, headers)
          rescue RestClient::ExceptionWithResponse => e
            @response = e.response
          end
        end
      else
        payload = {'available_quantity' => @new_quantity }.to_json
        begin
          @response = RestClient.put(url, payload, headers)
        rescue RestClient::ExceptionWithResponse => e
          @response = e.response
        end
      end
    end
  end
end
