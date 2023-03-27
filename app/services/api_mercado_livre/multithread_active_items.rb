require 'typhoeus'
require 'faraday'

# ML Api
module ApiMercadoLivre
    class MultithreadActiveItems < ApplicationService
      def initialize(seller)
        puts seller
        @seller = Seller.find_by(nickname: seller)
        @response
        @new_url = ""
      end
  
      def call
        active_items
        @response
      end
  
      def active_items
        ApiMercadoLivre::AuthenticationService.call(@seller)
        headers = { 'Authorization' => "Bearer #{@seller.access_token}",
                      'content-type' => 'application/json',
                      'accept' => 'application/json' }
        url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{@seller.ml_seller_id}&shipping_cost=free&price=*-70.0&status=active&attributes=seller_id"
        hydra = Typhoeus::Hydra.hydra
        first_request = Typhoeus::Request.new(url, method: :get, headers: headers)
        hydra.queue first_request
        hydra.run
        resp = JSON.parse(first_request.response.body)
        pp resp
      end
       

    end
  end