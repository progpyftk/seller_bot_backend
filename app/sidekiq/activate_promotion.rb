# populate_tiny_db.rb
class ActivatePromotion
    include Sidekiq::Worker
  
    sidekiq_options unique: :until_executed, unique_args: :unique_args
    sidekiq_options retry: false
  
    def self.unique_args(args)
      # Use the first argument as the unique identifier
      args.first
    end
  
    def perform(seller_id, type, promotion_id)
      puts '** SIDEKIQ JOB STARTED  -  ATIVADOR DE PROMOÇÃO ** '
      seller = Seller.find(seller_id)
      result = ApiMercadoLivre::PromotionItemsActivator.call(seller, type, promotion_id) 
      pp result
      result
    end

  end
  