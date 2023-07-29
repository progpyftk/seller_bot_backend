
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
    url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?logistic_type=fulfillment&labels=without_stock"

    # Fetch the API response for the URL with the given authorization header.
    resp = fetch_api_response(url, auth_header)
    pp resp['results']
    # Skip further processing if there are no items for the seller.
    next if resp['results'].blank?

    # If there are items, then fetch all seller items data using the API response - resp['results'] - the ml_items_ids.
    seller_items_data = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller, resp['results'])

    # Parse and push the item data for each seller item to the @items array.
    parsed_seller_items = parse_and_push_items(seller, seller_items_data)
    @items.push(*parsed_seller_items)
  end
    puts 'pp @items'

  # Render the @items array as JSON for the response with status 200.
  render json: @items, status: 200
end

  def to_increase_stock
    items_without_stock = Item.where.not(logistic_type: 'fulfillment').where(available_quantity: 0)
    @items_need_increase_stock = []
    items_without_stock.each do |item|
      result = LogisticEvent.where(item_id: item.ml_item_id)
                            .where(old_logistic: 'fulfillment')
                            .where(change_time: (Time.now.midnight - 200.day)..(Time.now.midnight + 2.day))
                            .order('change_time').last
      @items_need_increase_stock.push(item) unless result.nil?
    end

    render json: @items_need_increase_stock, status: 200
    # render json: items_without_stock, status: 200
  end

  def get_sku_qtt(sku)
    stock = Stock.find_by(sku: sku)
    if stock.nil?
      puts "Stock not found for SKU: #{sku}"
      return 0
    end
    stock.quantity
  end

  def flex
    ApiBling::StockService.call
    items_full = Item.where(logistic_type: 'fulfillment')
    @linhas_tabela = items_full.flat_map do |item|
      if item.variations.present?
        item.variations.each_with_object([]) do |item_variation, result|
          next unless item_variation.sku.present?
  
          result << {
            ml_item_id: item_variation.item_id,
            variation_id: item_variation.variation_id,
            variation: true,
            seller_nickname: item.seller.nickname,
            link: item.permalink,
            sku: item_variation.sku,
            quantity: get_sku_qtt(item_variation.sku),
            flex: item.flex
          }
        end
      else
        {
          ml_item_id: item.ml_item_id,
          variation_id: nil,
          variation: false,
          seller_nickname: item.seller.nickname,
          link: item.permalink,
          sku: item.sku,
          quantity: get_sku_qtt(item.sku),
          flex: item.flex
        }
      end
    end
    render json: @linhas_tabela, status: 200
  end

  def flex_turn_off
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    resposta = ApiMercadoLivre::FlexTurnOff.call(item)
    render json: resposta, status: 200
  end

  private

  # Fetch the API response for the given URL and authorization header.
  # Handle any API request errors, and return an empty hash in case of errors.
  def fetch_api_response(url, auth_header)
    JSON.parse(RestClient.get(url, auth_header))
  rescue StandardError => e
    puts "Error fetching data from API: #{e.message}"
    {}
  end
  
  # Parse and push the item data for each seller item to the @items array.
  def parse_and_push_items(seller, seller_items_data)
    @parsed_items = []
    seller_items_data.each do |seller_item|
      # Create a parsed item hash for each seller item
      @parsed_items.push({
        ml_item_id: seller_item['body']['id'],
        seller_id: seller.nickname,
        title: seller_item['body']['title'],
        permalink: seller_item['body']['permalink'],
        price: seller_item['body']['price'],
        available_quantity: seller_item['body']['available_quantity'],
        sold_quantity: seller_item['body']['sold_quantity'],
        logistic_type: seller_item['body']['shipping']['logistic_type']
      })
    end
    @parsed_items
  end

  





end
