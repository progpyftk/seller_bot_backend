# ML Api
module ApiMercadoLivre
    # retorna a lista dos MLB que estão no full e pausados (sem os dados, apenas MLB)
    class FulfillmentPausedItems < ApplicationService
    
        def initialize(seller)
            @seller = seller
            @filtered_items = []
        end
  
      def call
        filter_items
      end
  
      # retorna uma lista coms os MLBs filtrados
      def filter_items
        url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?search_type=scan&limit=100&logistic_type=fulfillment&status=paused"
        response = JSON.parse(RestClient.get(url, auth_header(@seller)))
        if not response.blank?
          @filtered_items.push(*response['results'])
          scroll_id = response['scroll_id']
          url = url + "&scroll_id=#{scroll_id}"
          until response['results'].empty?
              response = JSON.parse(RestClient.get(url, auth_header(@seller)))
              @filtered_items.push(*response['results'])
          end
        end
        @filtered_items
      end

      def auth_header(seller)
        ApiMercadoLivre::AuthenticationService.call(seller)
        { 'Authorization' => "Bearer #{seller.access_token}" }
      end
    end
  end
  