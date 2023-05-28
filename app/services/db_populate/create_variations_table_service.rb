# ML Api
module DbPopulate
    # faz o update da base de dado de acordo com a API do ML
    class CreateVariationsTableService < ApplicationService
      def call
        all_sellers
      end
  
      def all_sellers
        Seller.all.each do |seller|
          next unless seller.auth_status == '200'
  
          all_items_raw = ApiMercadoLivre::FetchAllItemsIdsBySeller.call(seller)
          all_items_raw.each do |parsed_item|
            if parsed_item.nil?
              # pass
            end
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
          nil
        end
      end
  
      def populate_db_variations(parsed_item)
        return unless parsed_item['body']['variations'].present?
  
        item = Item.find(parsed_item['body']['id'])
        parsed_item['body']['variations'].each do |variation|
          # aqui temos que testar, pois alguns items não possuem a variação nos dados gerais, apenas nos dados fiscais
          # logo, para aqueles que não tiverem os dados nos dados gerais, fazer uma requisição na APi de dados fiscais 
          @variation_sku = check_variation_sku(item_id, variation)
          attributes = {
            variation_id: variation['id'],
            sku: variation['seller_custom_field']
          }
          
          begin
            variation = Variation.find(variation['id'])
            variation.update(attributes)
          rescue ActiveRecord::RecordNotFound
            item.variations.create(attributes)
            nil
          end
        end
      end
  
      def item_attributes(parsed_item)
        # tratamento necessário do sku
        @sku = nil
        if parsed_item['body']['seller_custom_field'].blank?
          parsed_item['body']['attributes'].each do |attribute|
            if attribute['id'] == 'SELLER_SKU'
              @sku = attribute['value_name']
            end
          end
        else
          @sku = parsed_item['body']['seller_custom_field']
        end
  
        # tratamento flex
        @flex = false
        if parsed_item['body']['shipping']['tags'].blank?
          @flex = false
        else
          if parsed_item['body']['shipping']['tags'].include?('self_service_in')
            @flex = true
          end
        end
  
        @variation = if parsed_item['body']['variations'].present? ? true : false
    
        {
          ml_item_id: parsed_item['body']['id'],
          variation: @variation
          title: parsed_item['body']['title'],
          permalink: parsed_item['body']['permalink'],
          price: parsed_item['body']['price'],
          base_price: parsed_item['body']['base_price'],
          available_quantity: parsed_item['body']['available_quantity'],
          sold_quantity: parsed_item['body']['sold_quantity'],
          logistic_type: parsed_item['body']['shipping']['logistic_type'],
          free_shipping: parsed_item['body']['shipping']['free_shipping'],
          sku: @sku,
          flex: @flex
        }
      end
    end
  end
  