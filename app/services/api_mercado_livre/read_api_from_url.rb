require 'rest-client'
require 'json'

# ML Api
module ApiMercadoLivre
  # retornar uma lista com todos os anuncios do vendedors, apenas os ids
  class ReadApiFromUrl < ApplicationService

    def initialize(seller, urls_list)
      @seller = seller
      @urls_list = urls_list
      @response = []
    end

    def call
      read_api
    end
    
    def read_api
      ApiMercadoLivre::AuthenticationService.call(@seller)
      auth_header = { 'Authorization' => "Bearer #{@seller.access_token}" }
      @urls_list.each do |url|
        resp = JSON.parse(RestClient.get(url, auth_header))
        @response.push(*resp)
      end
      @response
    end
  end
end
