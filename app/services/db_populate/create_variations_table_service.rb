module DbPopulate
  class CreateVariationsTableService < ApplicationService
    def call
      all_sellers
    end

    def all_sellers
      Seller.all.each do |seller|
        next unless seller.auth_status == '200'

        ApiMercadoLivre::FetchAllItemsIdsBySeller.call(seller).each do |parsed_item|
          next if parsed_item.nil?

          populate_db(parsed_item, seller)
          populate_db_variations(parsed_item)
        end
      end
    end

    def populate_db(parsed_item, seller)
      attributes = item_attributes(parsed_item)
      begin
        item = Item.find(attributes[:ml_item_id])
        item.update(attributes)
      rescue ActiveRecord::RecordNotFound
        seller.items.create(attributes)
      end
    end

    def populate_db_variations(parsed_item)
      return unless parsed_item['body']['variations'].present?

      item = Item.find(parsed_item['body']['id'])
      parsed_item['body']['variations'].each do |variation|
        variation_sku = check_variation_sku(item.id, variation)
        attributes = {
          variation_id: variation['id'],
          sku: variation_sku
        }

        begin
          variation_record = item.variations.find(variation['id'])
          variation_record.update(attributes)
        rescue ActiveRecord::RecordNotFound
          item.variations.create(attributes)
        end
      end
    end

    def item_attributes(parsed_item)
      sku = determine_sku(parsed_item)
      flex = determine_flex(parsed_item)
      variation = parsed_item['body']['variations'].present?

      {
        ml_item_id: parsed_item['body']['id'],
        variation: variation,
        title: parsed_item['body']['title'],
        permalink: parsed_item['body']['permalink'],
        price: parsed_item['body']['price'],
        base_price: parsed_item['body']['base_price'],
        available_quantity: parsed_item['body']['available_quantity'],
        sold_quantity: parsed_item['body']['sold_quantity'],
        logistic_type: parsed_item['body']['shipping']['logistic_type'],
        free_shipping: parsed_item['body']['shipping']['free_shipping'],
        sku: sku,
        flex: flex
      }
    end

    private

    def determine_sku(parsed_item)
      if parsed_item['body']['seller_custom_field'].blank? && parsed_item['body']['attributes'].present?
        parsed_item['body']['attributes'].find { |attr| attr['id'] == 'SELLER_SKU' }&.fetch('value_name', nil)
      else
        parsed_item['body']['seller_custom_field']
      end
    end

    def determine_flex(parsed_item)
      parsed_item['body']['shipping']['tags']&.include?('self_service_in') || false
    end
  end
end
