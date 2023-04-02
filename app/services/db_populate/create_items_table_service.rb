# ML Api
module DbPopulate
  # o correto para essa tabela eh apagar e criar uma nova
  class CreateItemsTableService < ApplicationService

    def call
      all_sellers
    end

    def all_sellers
      Seller.all.each do |seller|
        if seller.auth_status == '200'
          all_items_raw = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller)
          all_items_raw.each do |parsed_item|
            populate_db(parsed_item, seller)
          end
        end
      end
    end

    def populate_db(parsed_item, seller)
      attributes = item_attributes(parsed_item)
      pp attributes
      
      begin
        item = Item.find(attributes[:ml_item_id])
        item.update(attributes)
      rescue ActiveRecord::RecordNotFound
        seller.items.create(attributes)
        nil
      end
    end


    def fetch_sku(parsed_item)
      sku = nil
      if parsed_item['body']['seller_custom_field'].blank?
        if not parsed_item['body']['attributes'].blank?
          parsed_item['body']['attributes'].each do |attribute|
            if attribute['id'] == 'SELLER_SKU'
              sku = attribute['value_name']
            end
          end
        end
      else
        sku = parsed_item['body']['seller_custom_field']
      end
      sku
    end

    def fetch_flex(parsed_item)
      flex = false
      if parsed_item['body']['shipping']['tags'].blank?
        flex = false
      else
        if parsed_item['body']['shipping']['tags'].include?('self_service_in')
          flex = true
        end
      end
      flex
    end

    def item_attributes(parsed_item)
      puts 'entrei no item_attributes'
      sku = fetch_sku(parsed_item)
      puts 'passei do sku'
      flex = fetch_flex(parsed_item)
      puts 'passei do flex'
      variation = false
      if parsed_item['body']['variations'].present?
        variation = true
      end
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
  end
end
