# ML Api
module ApiMercadoLivre
  # fetch all items data from a seller
  class FetchAllItemsDataBySeller < ApplicationService

    def initialize(seller)
      ApiMercadoLivre::AuthenticationService.call(seller)
      @items_ids = ApiMercadoLivre::FetchAllItemsIdsBySeller.call(seller)
      @seller = seller
    end

    def call
      puts "*** Iniciando: ApiMercadoLivre::FetchAllItemsDataBySeller *** "
      puts "Seller: #{@seller.nickname}"
      fetch_items_data
      puts " *** Iniciando: ApiMercadoLivre::FetchAllItemsDataBySeller *** "
      puts " Resposta final com todos os dados de todos os anúncios "
      @response
    end

    def fetch_items_data
      urls_list = FunctionalServices::BuildUrlList.call(@items_ids) # lista das urls que serão chamadas (de 20 em 20)
      @response = []
      puts ' -- urls sendo chamadas ---'
      urls_list.each do |url|
        puts url
        @response.push(*JSON.parse(RestClient.get(url, auth_header)))
      end
      @response
    end

    def auth_header
      { 'Authorization' => "Bearer #{@seller.access_token}" }
    end
  end
end
