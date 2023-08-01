# ML Api
module ApiMercadoLivre
  # fetch all items data from a seller
  class FetchAllItemsDataBySeller < ApplicationService

    def initialize(seller, items_ids)
      ApiMercadoLivre::AuthenticationService.call(seller)
      # @items_ids = ApiMercadoLivre::FetchAllItemsIdsBySeller.call(seller)
      @items_ids = items_ids
      @seller = seller
    end

    def call
      fetch_items_data
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
