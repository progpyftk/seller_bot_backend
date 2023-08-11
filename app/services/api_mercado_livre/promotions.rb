# ML Api
module ApiMercadoLivre
    # retorna a chamada de um anuncio
    # nova_api: envie a query param app_version=v2

    class Promotions < ApplicationService
  
      def initialize()
        puts 'entrei no PromotionsService'
        @seller = Seller.find_by(ml_seller_id: "137131292")
      end
  
      def call
        seller_promotions
      end


      def seller_promotions_deal(promotion_id)
        # fazer um loop para os 100 primeiros anúncios

        # pegar os anúncios da promoção


        # Dados da chamada
        promotion_id = "P-MLB12725010"

        # Dados da chamada
        access_token = @seller.access_token
        user_id = @seller.ml_seller_id


         # Headers da requisição
         headers = {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        }

        # URL da API
        url = "https://api.mercadolibre.com/seller-promotions/users/#{user_id}?app_version=v2"

        # Fazendo a chamada HTTP POST
        response = HTTParty.get(url, headers: headers)
        pp response


        puts '-------'
        puts '-------'
        url = "https://api.mercadolibre.com/seller-promotions/promotions/P-MLB12725010/items?promotion_type=DEAL&app_version=v2"
        # Fazendo a chamada HTTP GET
        response = HTTParty.get(url, headers: headers)
        pp response



        # Dados da chamada
        promotion_id = "P-MLB12725010"
        promotion_type = "DEAL"
        item_id = 'MLB3676844874'
        deal_price = 65
        top_deal_price = 57

        # URL da API
        url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"

        # Corpo da requisição em formato JSON
        body = {
          "promotion_id" => promotion_id,
          "promotion_type" => promotion_type,
          "deal_price" => deal_price,
        }.to_json

        puts '---------'
        puts '---------'
        # Fazendo a chamada HTTP POST
        response = HTTParty.post(url, headers: headers, body: body)
        pp response
        # Verifica a resposta
        if response.success?
          puts 'Chamada bem-sucedida!'
          puts response.body
        else
          puts "Erro na chamada do anúncio  "
          puts response.code
          puts response.body
        end
    
      end



      
      
  
      def auth_header
        ApiMercadoLivre::AuthenticationService.call(@seller)
        { 'Authorization' => "Bearer #{@seller.access_token}", 
        'content-type' => 'application/json',
        'accept' => 'application/json'
        }
      end

    end
  end