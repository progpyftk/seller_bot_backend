# ML Api
module ApiMercadoLivre
  # retorna a chamada de um anuncio
  class ItemFiscalData < ApplicationService

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
      # https://developers.mercadolivre.com.br/pt_br/envio-dos-dados-fiscais
      url = "https://api.mercadolibre.com/items/#{@item}/fiscal_information/detail"
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
