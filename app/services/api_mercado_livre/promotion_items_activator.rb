module ApiMercadoLivre
    # classe que ativa as promoçoes
    class PromotionItemsActivator < ApplicationService

      def initialize(seller,type, promotion_id)
        @seller = seller
        @type = type
        @promotion_id = promotion_id
      end

      # Método de entrada para recuperar as promoções do vendedor
      def call
        puts "Iniciando a ativação dos anúncios da promoção selecionada"
        activate_promotion
      end

      private

      # Recupera as promoções do vendedor da API do Mercado Livre
      def activate_promotion
        # ativação das campanhas de acordo com seu type
        if @type == "DEAL"
          activate_deal_promotion(@seller, @promotion_id, "DEAL")
        end

        if @type == "LIGHTNING"
          puts 'Ativação do tipo LIGHTNING'
          activate_lightning_promotion(@seller, @promotion_id, "LIGHTNING")
        end

        if @type == "MARKETPLACE_CAMPAIGN"
          activate_marketplacecampaing_promotion(@seller, @promotion_id, "MARKETPLACE_CAMPAIGN")
        end
      end

      def activate_deal_promotion(seller, promotion_id, promotion_type)
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "DEAL", 100)
        channel_key = "#{promotion_id}_#{seller.ml_seller_id}"
        puts "VERICARRRR"
        puts channel_key
        if items.present?
          items.each do |item|
            PromotionJobTracker.job_enqueued(channel_key)
            ApplyDealPromotionJob.perform_async(item, seller.ml_seller_id, promotion_id, promotion_type)
          end
        else
          puts "No eligible announcements for campaign: #{promotion_id} #{promotion_type}"
        end
        puts "Enqueued all items for promotion #{promotion_id} in Sidekiq."
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
                @ativados = @ativados + 1
                Rails.logger.info "Promoção aplicada com sucesso"
                Rails.logger.info "#{response.body.to_json}"
              else
                @nao_ativados = @nao_ativados + 1
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
                @ativados = @ativados + 1
                Rails.logger.info "Promoção aplicada com sucesso"
                Rails.logger.info "#{response.body.to_json}"
              else
                @nao_ativados = @nao_ativados + 1
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
