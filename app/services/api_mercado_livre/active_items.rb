# ML Api
module ApiMercadoLivre
  class ActiveItems < ApplicationService
    def initialize(seller)
      @seller = seller
      @filtered_items = []
    end

    def call
      active_items
    end

    def active_items
      ApiMercadoLivre::AuthenticationService.call(@seller)
      headers = { 'Authorization' => "Bearer #{@seller.access_token}",
                    'content-type' => 'application/json',
                    'accept' => 'application/json' }
      url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&limit=100&status=active"
      response = JSON.parse(RestClient.get(url, headers))
        if not response.blank?
          @filtered_items.push(*response['results'])
          scroll_id = response['scroll_id']
          url = url + "&scroll_id=#{scroll_id}"
          until response['results'].empty?
              response = JSON.parse(RestClient.get(url, headers))
              @filtered_items.push(*response['results'])
          end
        end
        @filtered_items
    end
  end
end
