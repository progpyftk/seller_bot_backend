
class FulfillmentController < ApplicationController
  before_action :authenticate_user!
  
  # Controller action to fetch items from MercadoLibre API for sellers associated with the current user.
  def index
    @items = []

    # Retrieve sellers associated with the current user, preloading their associated items.
    current_user.sellers.each do |seller|
      puts seller.nickname
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }

      # Build the MercadoLibre API URL for fetching seller items without stock in fulfillment.
      url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?search_type=scan&labels=without_stock&logistic_type=fulfillment"

      # Fetch the API response for the URL with the given authorization header.
      resp = fetch_item_ids(url, auth_header, seller.ml_seller_id)

      pp resp

      # Skip further processing if there are no items for the seller.
      next if resp.blank?

      # If there are items, then fetch all seller items data using the API response - resp['results'] - the ml_items_ids.
      seller_items_data = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller, resp)

      # Parse and push the item data for each seller item to the @items array.
      parsed_seller_items = index_parse_and_push_items(seller, seller_items_data)
      @items.push(*parsed_seller_items)
    end

  # Render the @items array as JSON for the response with status 200.
  render json: @items, status: 200
  end


  def flex
    # atualiza a BD com o estoque atual
    tiny = ApiTiny::TinyApiService.new()
    tiny.fetch_products
    @items = []
    # Iterate through each seller associated with the current user
    current_user.sellers.each do |seller|
      puts seller.nickname
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }

      # Build the MercadoLibre API URL to get seller items in fulfillment
      url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?search_type=scan&logistic_type=fulfillment"

      # Fetch the seller items' IDs using the API response
      item_ids = fetch_item_ids(url, auth_header, seller.ml_seller_id)

      # Skip further processing if there are no items for the seller.
      next if item_ids.blank?

      # Fetch all seller items data using the item IDs
      seller_items_data = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller, item_ids)

      # Parse and push the item data for each seller item to the @items array.
      parsed_seller_items = flex_parse_and_push_items(seller, seller_items_data)

      # para cada um desses items preciso saber se tem variação ou não
      # se não tiver, preciso saber o SKU do anúncio
      # tiver variação, preciso saber quantas e quais: variation_id, sku de cada variação

      @items.push(*parsed_seller_items)
    end

    # Render the @items array as JSON for the response with status 200.
    render json: @items, status: 200
  end

  private

  #Fetch item IDs for the seller using the given API URL and authorization header.
  def fetch_item_ids(url, auth_header, ml_seller_id)
    item_ids = []
  
    # Perform initial request to get item IDs and handle scroll_id for pagination.
    begin
      resp = JSON.parse(RestClient.get(url, auth_header))
      item_ids.push(*resp['results'])
      url = "https://api.mercadolibre.com/users/#{ml_seller_id}/items/search?search_type=scan&scroll_id=#{resp['scroll_id']}&limit=100"
    end until resp['results'].blank?
  
    item_ids
  rescue StandardError => e
    puts "Error fetching data from API: #{e.message}"
    []
  end
  
  # Parse and push the item data for each seller item to the @items array.
  def index_parse_and_push_items(seller, seller_items_data)
    parsed_items = []
  
    seller_items_data.each do |seller_item|
      flex = seller_item['body']['shipping']['tags'].include?('self_service_in')
  
      # Create a parsed item hash for each seller item
      if seller_item['body']['available_quantity'] == 0
        parsed_items << {
          ml_item_id: seller_item['body']['id'],
          seller_id: seller.nickname,
          title: seller_item['body']['title'],
          permalink: seller_item['body']['permalink'],
          price: seller_item['body']['price'],
          available_quantity: seller_item['body']['available_quantity'],
          sold_quantity: seller_item['body']['sold_quantity'],
          logistic_type: seller_item['body']['shipping']['logistic_type'],
        }
      end 
    end
  
    parsed_items
  end


  def flex_parse_and_push_items(seller, seller_items_data)
    
    parsed_items = []
    
    # Iterate through each seller item data
    seller_items_data.each do |seller_item|
      # Determine if the item has variations and if it is eligible for flex shipping
      flex = seller_item['body']['shipping']['tags'].include?('self_service_in')
      sku = nil
  
      # Determine if the item has variations
      variation = seller_item['body']['variations'].present?
  
      # If the item has variations, process each variation
      if variation
        seller_item['body']['variations'].each do |variation_data|
          # Find SKU information for each variation
          sku_dict = variation_data['attributes'].find { |dict| dict["id"] == "SELLER_SKU" }
          sku = sku_dict['value_name'] if sku_dict
  
          # Build and add the parsed item to the parsed_items array
          parsed_items << build_parsed_item(seller_item, seller, flex, true, variation_data, sku)
        end
      else
        # If the seller_custom_field is blank (missing), try to find the SKU information in the attributes array
        # The 'find' method searches for the first attribute with the 'id' equal to 'SELLER_SKU'
        # If found, extract the SKU value and assign it to the 'sku' variable; otherwise, 'sku' remains 'nil'
        if seller_item['body']['seller_custom_field'].blank?
          sku_attribute = seller_item['body']['attributes'].find { |attribute| attribute['id'] == 'SELLER_SKU' }
          sku = sku_attribute['value_name'] if sku_attribute
        else
          # If the seller_custom_field is present, use it as the SKU
          sku = seller_item['body']['seller_custom_field']
        end
  
        # Process the item itself and add it to the parsed_items array
        parsed_items << build_parsed_item(seller_item, seller, flex, false, nil, sku)
      end
    end
  
    parsed_items
  end
  
  def build_parsed_item(item_data, seller, flex, has_variation, variation_data, sku)
    # Build a hash representing the parsed item
    {
      ml_item_id: item_data['body']['id'],
      seller_id: seller.nickname,
      title: item_data['body']['title'],
      permalink: item_data['body']['permalink'],
      price: item_data['body']['price'],
      available_quantity: item_data['body']['available_quantity'],
      sold_quantity: item_data['body']['sold_quantity'],
      logistic_type: item_data['body']['shipping']['logistic_type'],
      flex: flex,
      variation: has_variation,
      variation_id: variation_data ? variation_data['id'] : nil,
      store_quantity: 0,
      sku: sku
    }
  end
  

  

end







