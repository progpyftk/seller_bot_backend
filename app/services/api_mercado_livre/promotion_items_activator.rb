# 1 - recebe todas as ofertas disponiveis para o seller SellerPromotionsService
# 2 - para cada uma dessas promoções encontra os anúncios disponíveis PromotionItemsService
# 3 - para cada um desses anúncios, de acordo com o tipo de promoção faz a sua ativação
# melhorias futuras
# ativação com base no markup
# tratamento da ativação


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
        Rails.logger.flush
        seller_available_promotions
      end
  
      private
  
      # Recupera as promoções do vendedor da API do Mercado Livre
      def seller_available_promotions

        # ativação das campanhas de acordo com seu type
        if @type == "DEAL"
          activate_deal_promotion(seller, @promotion_id, "DEAL")
        end

        if @type == "LIGHTNING"
          activate_lightning_promotion(seller, @promotion_id, "LIGHTNING")
        end

        if @type == "MARKETPLACE_CAMPAIGN"
          activate_marketplacecampaing_promotion(seller, @promotion_id, "MARKETPLACE_CAMPAIGN")
        end

      end

      def activate_deal_promotion(seller, promotion_id, promotion_type)
        Rails.logger.info "#{Time.now} ------ #{seller.nickname} -----------------"
        Rails.logger.info "#{Time.now} ------ Anúncios da Campanha: #{promotion_id} -----------------"
        # Encontra os items que podem fazer parte dessa promoção (started, candidate, pending)
        # essa é funçao que ira retornar todos anuncios aptos para a campanha em questao, de onde tiramos os dados para colocar no card
        puts "iniciado a leitura dos items da promocao"
        items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_id, "DEAL")
        puts "terminou a leitura dos items da promocao"
        puts items.length
      end

    end
  end
  