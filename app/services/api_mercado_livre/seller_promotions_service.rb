module ApiMercadoLivre
    # Classe para recuperar promoções disponíveis para um vendedor
    class SellerPromotionsService < ApplicationService
      def initialize(seller)
        @seller = seller
      end
  
      # Método de entrada para recuperar as promoções do vendedor
      def call
        fetch_seller_promotions
      end
  
      private
  
      # Recupera as promoções do vendedor da API do Mercado Livre
      def fetch_seller_promotions
        access_token = @seller.access_token
        user_id = @seller.ml_seller_id
        
        # Cabeçalhos para a requisição HTTP
        headers = {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        }
        
        # URL da API para buscar as promoções do vendedor
        url = "https://api.mercadolibre.com/seller-promotions/users/#{user_id}?app_version=v2"
        
        # Fazendo a chamada HTTP GET para recuperar as promoções
        response = HTTParty.get(url, headers: headers)
        
        # Verifica a resposta
        handle_response(response)
      end
  
      # Trata a resposta da chamada HTTP
      def handle_response(response)
        if response.success?
          #puts 'Chamada bem-sucedida!'
          return response
        else
          puts 'Erro na chamada das promoções do vendedor'
          puts "Código de erro: #{response.code}"
          puts "Corpo da resposta: #{response.body}"
          return response
        end
      end
    end
  end
  