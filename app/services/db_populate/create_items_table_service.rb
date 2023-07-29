# ML Api
module DbPopulate
  # o correto para essa tabela eh apagar e criar uma nova
  class CreateItemsTableService < ApplicationService

    def call
      puts '*** Iniciando DbPopulate::CreateItemsTableService ***'
      all_sellers
    end

    def all_sellers
      Seller.all.each do |seller|
        puts "Seller: #{seller.nickname}"
        # deleta todos os items da base de dados desse seller
        seller.items.destroy_all
        if seller.auth_status == '200'
          all_items_raw = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller)
          puts '** Tamanho do all_items_raw ***'
          puts all_items_raw.length
          all_items_raw.each do |parsed_item|
            populate_db(parsed_item, seller)
          end
        end
      end
    end

    def populate_db(parsed_item, seller)
      attributes = item_attributes(parsed_item)
      begin
        seller.items.create(attributes)
        create_variations(parsed_item)
      rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
        # Error handling for unique constraint violation
        puts e.message
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

    def create_variations(parsed_item)
      item = Item.find_by(ml_item_id: parsed_item['body']['id'])
      if item.variation  
        item.variations.destroy_all
        parsed_item['body']['variations'].each do |variation|
          sku_dict = variation['attributes'].find { |dict| dict["id"] == "SELLER_SKU" }
          begin
            puts 'criando variação'
            if sku_dict.nil?
              item.variations.create(variation_id: variation['id'], sku: nil )
            else
              puts "varaition_id: #{variation['id']}   sku: #{sku_dict['value_name']}"
              item.variations.create(variation_id: variation['id'], sku: sku_dict['value_name'])
            end
          rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
            # Error handling for unique constraint violation
            puts e.message
          end
        end
      end
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
