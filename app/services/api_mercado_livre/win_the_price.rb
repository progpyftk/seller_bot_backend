# ML Api
module ApiMercadoLivre
    # retorna a chamada de um anuncio
    class WinThePrice < ApplicationService
  
      def initialize(item_id)
        @item_id = item_id
        @seller = nil
        @response = nil
      end
  
      def call
        search_item
        @response
      end
  
      def search_item
        @seller = ApiMercadoLivre::FindSellerByItemId.call(@item_id)  
        url = "https://api.mercadolibre.com/items/#{@item_id}/health/actions"
        begin
          @response = (RestClient.get(url, auth_header))
        rescue RestClient::ExceptionWithResponse => e
          puts 'Deu algum erro no RestClient'
        end
      end
  
      def auth_header
        # ApiMercadoLivre::AuthenticationService.call(@seller)
        { 'Authorization' => "Bearer #{@seller.access_token}" }
      end
    end
  end