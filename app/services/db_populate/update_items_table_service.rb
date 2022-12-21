# ML Api
module DbPopulate
  # faz o update da base de dado de acordo com a API do ML
  class UpdateItemsTableService < ApplicationService
    def call
      all_sellers
    end

    def all_sellers
      Seller.all.each do |seller|
        next unless seller.auth_status == '200'

        items_ids = ApiMercadoLivre::AllSellerItemsService.call(seller)
        all_items_raw = ApiMercadoLivre::ItemMultigetDataService.call(items_ids, seller)
        all_items_raw.each do |parsed_item|
          if parsed_item.nil?
            # pass
          end
          populate_db(parsed_item, seller)
        end
      end
    end

    def populate_db(parsed_item, seller)
      attributes = item_attributes(parsed_item)
      begin
        item = Item.find(attributes[:ml_item_id])
        item.update(attributes)
        updates_hash = item.previous_changes
        DbPopulate::UpdateEventTrackService.call(item, updates_hash) unless item.previous_changes.empty?
      rescue ActiveRecord::RecordNotFound
        seller.items.create(attributes)
        nil
      end
    end

    def populate_db_variations(parsed_item)
      return unless parsed_item['body']['variations'].present?

      puts 'encontrou variacao, salvando'
      parsed_item['body']['variations'].each do |variation|
        variation = Variation.find_or_initialize_by(variation_id: variation['id'])
        variation.variation_id = variation['id']
        variation.sku = variation['seller_custom_field']
        variation.ml_item_id = parsed_item['body']['id']
        variation.save
      end
    end

    def item_attributes(parsed_item)
      {
        ml_item_id: parsed_item['body']['id'],
        title: parsed_item['body']['title'],
        permalink: parsed_item['body']['permalink'],
        price: parsed_item['body']['price'],
        base_price: parsed_item['body']['base_price'],
        available_quantity: parsed_item['body']['available_quantity'],
        sold_quantity: parsed_item['body']['sold_quantity'],
        logistic_type: parsed_item['body']['shipping']['logistic_type'],
        free_shipping: parsed_item['body']['shipping']['free_shipping'],
        sku: parsed_item['body']['seller_custom_field']
      }
    rescue StandardError => e
      # puts e
    end
  end
end
