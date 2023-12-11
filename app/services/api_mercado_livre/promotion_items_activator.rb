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
          activate_lightning_promotion(@seller, @promotion_id, "LIGHTNING")
        end

        if @type == "MARKETPLACE_CAMPAIGN"
          activate_marketplacecampaing_promotion(@seller, @promotion_id, "MARKETPLACE_CAMPAIGN")
        end
      end

      def activate_deal_promotion(seller, promotion_id, promotion_type)
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "DEAL", 500)
        channel_key = "#{promotion_id}_#{seller.ml_seller_id}"
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
        Rails.logger.info "------ Anúncios aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} --------"
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "LIGHTNING", 500)
        channel_key = "#{promotion_id}_#{seller.ml_seller_id}"
        if items.present?
          items.each do |item|
            PromotionJobTracker.job_enqueued(channel_key)
            ApplyLightningPromotionJob.perform_async(item, seller.ml_seller_id, promotion_id, promotion_type)
          end
        else
          puts "Item veio em branco, não funcionou a chamada"
        end
      end

      def activate_marketplacecampaing_promotion(seller, promotion_id, promotion_type)
        Rails.logger.info "------ Anúncios aptos para a Promoção: #{promotion_id} do tipo: #{promotion_type} --------"
        channel_key = "#{promotion_id}_#{seller.ml_seller_id}"
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "MARKETPLACE_CAMPAIGN", 500)
        if items.present?
          items.each do |item|
            PromotionJobTracker.job_enqueued(channel_key)
            ApplyMarketplacecampaingPromotionJob.perform_async(item, seller.ml_seller_id, promotion_id, promotion_type)
          end
        else
          puts "Item veio em branco, não funcionou a chamada"
        end
      end

    end
  end
