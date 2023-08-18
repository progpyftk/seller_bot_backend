# 1 - recebe todas as ofertas disponiveis para o seller SellerPromotionsService
# 2 - para cada uma dessas promoções encontra os anúncios disponíveis PromotionItemsService
# 3 - para cada um desses anúncios, de acordo com o tipo de promoção faz a sua ativação
# melhorias futuras
# ativação com base no markup
# tratamento da ativação


module ApiMercadoLivre
    # classe que ativa as promoçoes
    class PromotionItemsActivator < ApplicationService
      
  
      # Método de entrada para recuperar as promoções do vendedor
      def call
        Rails.logger.flush
        seller_available_promotions
      end
  
      private
  
      # Recupera as promoções do vendedor da API do Mercado Livre
      
      def seller_available_promotions
        items = {}
        Seller.all.each do |seller|
          Rails.logger.info "*******************************************"
          Rails.logger.info "*******************************************"
          Rails.logger.info seller.nickname
          # promocoes disponíveis para o seller
          seller_promotions = ApiMercadoLivre::SellerPromotionsService.call(seller)
          # mostra os detalhes das promocoes disponiveis para cada seller
          seller_promotions['results'].each do |promotion|
            Rails.logger.info " -------------------------------------------------- "
            Rails.logger.info "  Promotion ID: #{promotion["id"]}"
            Rails.logger.info "  Type: #{promotion["type"]}"
            Rails.logger.info "  Status: #{promotion["status"]}" 
            Rails.logger.info "  Name: #{promotion["name"]}"
            if promotion["benefits"]
              Rails.logger.info "  Benefits:"
              Rails.logger.info "    Type: #{promotion["benefits"]["type"]}"
              Rails.logger.info "    Meli Percent: #{promotion["benefits"]["meli_percent"]}"
              Rails.logger.info "    Seller Percent: #{promotion["benefits"]["seller_percent"]}"
            end
            if promotion["sub_type"]
              Rails.logger.info "  Sub Type: #{promotion["sub_type"]}"
            end

            # ativação das campanhas de acordo com seu typE
            if promotion["type"] == "DEAL"
              activate_deal_promotion(seller, promotion["id"], "DEAL")
            end

            if promotion["type"] == "LIGHTNING"
              activate_lightning_promotion(seller, promotion["id"], "LIGHTNING")
            end

            if promotion["type"] == "MARKETPLACE_CAMPAIGN"
              activate_marketplacecampaing_promotion(seller, promotion["id"], "MARKETPLACE_CAMPAIGN")
             end
      
          end
           
        end

      end

      def activate_deal_promotion(seller, promotion_id, promotion_type)
        Rails.logger.info "#{Time.now} ------ #{seller.nickname} -----------------"
        Rails.logger.info "#{Time.now} ------ Anúncios da Campanha: #{promotion_id} -----------------"
        # Encontra os items que podem fazer parte dessa promoção (started, candidate, pending)
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "DEAL")
        if !items.blank?
          Rails.logger.info "#{Time.now} - Quantidade de anúncios: #{items.length}"
          items.each do |item|
            Rails.logger.info "# Aplicando promoção no - #{item.to_json}"
            # função de aplicar a promo - nesse caso para cada tipo é uma forma diferente
            # TIPO DE PROMOÇÃO = DEAL
            if item['status'] == "candidate"
              item_id = item['id']
              deal_price = item['original_price'].to_f * 0.95
              url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"
              headers = {
                'Authorization' => "Bearer #{seller.access_token}",
                'Content-Type' => 'application/json'
              }
              body = {
                "promotion_id" => promotion_id,
                "promotion_type" => promotion_type,
                "deal_price" => deal_price.round(0),
              }.to_json
              response = HTTParty.post(url, headers: headers, body: body)
              if response.success?
                Rails.logger.info "Promoção aplicada com sucesso"
                Rails.logger.info "#{response.body.to_json}" 
              else
                puts "Erro no momento da ativação"
                Rails.logger.info "#{response.code.to_json}" 
                Rails.logger.info "#{response.body.to_json}" 
              end
            end
          end
        else
          puts "Item veio em branco, logo não há anúncios aptos para essa campanha: #{promotion_id}  #{promotion_type}"
        end
      end

      def activate_lightning_promotion(seller, promotion_id, promotion_type)
        Rails.logger.info " ------ PROMOÇÃO LIGHTNING -----------------"
        Rails.logger.info "------ #{seller.nickname} -----------------"
        Rails.logger.info "------ Anúncios aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} --------"
        # Encontra os items que podem fazer parte dessa promoção (started, candidate, pending)
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "LIGHTNING")
        # parametros estipulados pela campanha lightning para CADA ITEM
        # por padrão vamos colocar sempre:
        # preço: max_discounted_price
        # stock: stock_min
        # max_discounted_price
        # min_discounted_price
        # stock_min
        # stock_max
        # Rails.logger.info items.to_json
        if !items.blank?
          Rails.logger.info "Quantidade de anúncios: #{items.length} aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} ------"
          items.each do |item|
            Rails.logger.info "# Aplicando promoção no - #{item.to_json}"
            # função de aplicar a promo - nesse caso para cada tipo é uma forma diferente
            # TIPO DE PROMOÇÃO = LIGHTNING
            if item['status'] == "candidate"
              item_id = item['id']
              stock = item['stock']['min'] # por padrão vamos usara o estoque mínimo
              # coloquei o final XX.88 para saber as que foram por conta do lightning
              deal_price = (item['original_price']*0.94).round(0) - 0.12
              url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"
              headers = {
                'Authorization' => "Bearer #{seller.access_token}",
                'Content-Type' => 'application/json'
              }
              body = {
                "deal_price" => deal_price,
                "stock" => stock,
                "promotion_type" => promotion_type,
              }.to_json
              Rails.logger.info body 
              response = HTTParty.post(url, headers: headers, body: body)
              if response.success?
                Rails.logger.info "Promoção aplicada com sucesso"
                Rails.logger.info "#{response.body.to_json}" 
              else
                puts "Erro no momento da ativação"
                Rails.logger.info "#{response.code.to_json}" 
                Rails.logger.info "#{response.body.to_json}" 
              end
            end
          end
        else
          puts "Item veio em branco, não funcionou a chamada do ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, DEAL)"
        end
      end

      def activate_marketplacecampaing_promotion(seller, promotion_id, promotion_type)
        Rails.logger.info " ------ PROMOÇÃO MARKETPLACE_CAMPAIGN -----------------"
        Rails.logger.info "------ #{seller.nickname} -----------------"
        Rails.logger.info "------ Anúncios aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} --------"
        # Encontra os items que podem fazer parte dessa promoção (started, candidate, pending)
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "MARKETPLACE_CAMPAIGN")
        if !items.blank?
          Rails.logger.info "Quantidade de anúncios: #{items.length} aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} ------"
          items.each do |item|
            Rails.logger.info "# Aplicando promoção no - #{item.to_json}"
            # função de aplicar a promo - nesse caso para cada tipo é uma forma diferente
            # TIPO DE PROMOÇÃO = MARKETPLACE_CAMPAIGN
            if item['status'] == "candidate"
              item_id = item['id']
              promotion_id = promotion_id
              promotion_type = promotion_type
              url = "https://api.mercadolibre.com/seller-promotions/items/#{item_id}?app_version=v2"
              headers = {
                'Authorization' => "Bearer #{seller.access_token}",
                'Content-Type' => 'application/json'
              }
              body = {
                "promotion_id" => promotion_id,
                "promotion_type" => promotion_type
              }.to_json
              Rails.logger.info body 
              response = HTTParty.post(url, headers: headers, body: body)
              if response.success?
                Rails.logger.info "Promoção aplicada com sucesso"
                Rails.logger.info "#{response.body.to_json}" 
              else
                puts "Erro no momento da ativação"
                Rails.logger.info "#{response.code.to_json}" 
                Rails.logger.info "#{response.body.to_json}" 
              end
            end
          end
        else
          puts "Item veio em branco, não funcionou a chamada do ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, DEAL)"
        end
      end


      
    end
  end
  