require_relative '../services/api_mercado_livre/authentication_service'

class ItemController < ApplicationController
  before_action :authenticate_user!
  def add_stock
    DbPopulate::UpdateItemsTableService.call
    item_params = params.require(:item).permit(:quantity, :ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    begin
      resp = JSON.parse(ApiMercadoLivre::ChangeAvailableQuantity.call(item, item_params[:quantity]))
      # render json: resp, status: resp['status'].to_i
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end

  def retrieve_item
    resp = ApiMercadoLivre::ItemDataService.call(ml_item_id, seller)
    render json: resp, status: 200
  end

  def free_shipping
    @items = []

    # Retrieve sellers associated with the current user, preloading their associated items.
    current_user.sellers.each do |seller|
      puts seller.nickname
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }

      # Build the MercadoLibre API URL for fetching seller items with free shipping and price less than xx
      url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{seller.ml_seller_id}&price=95-100&shipping_cost=free" 

      # Fetch the API response for the URL with the given authorization header.
      resp = fetch_api_response(url, auth_header)
      Rails.logger.flush
      Rails.logger.info "hello, it's #{Time.now}"
      Rails.logger.info pp resp

      # Skip further processing if there are no items for the seller.
      next if resp['results'].blank?

      # aqui precisamos fazer o parte do resp['results'] no qual já tem os dados dos anuncios e não apenas os ids
      resp['results'].each do |item|
        puts item['id']
      end
      

      # Parse and push the item data for each seller item to the @items array.
      parsed_seller_items = parse_and_push_items(seller, seller_items_data)
      @items.push(*parsed_seller_items)
    end
      puts 'pp @items'

    # Render the @items array as JSON for the response with status 200.
    render json: @items, status: 200
  end

  def change_to_free_shipping
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    begin
      resp = JSON.parse(ApiMercadoLivre::FreeShipping.call(item))
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end

  def fiscal_data
    item_params = params.require(:item).permit(:ml_item_id)
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemFiscalData.call(item_params[:ml_item_id]))
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end

  def general_data
    item_params = params.require(:item).permit(:ml_item_id)
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemGeneralData.call(item_params[:ml_item_id]))
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end

  # atualização da base de dados de forma geral
  def update_database
    begin
      DbPopulate::CreateItemsTableService.call
      render json: {}, status: 200
    rescue RestClient::ExceptionWithResponse => e
      puts e.response
      render json: {}, status: 400
    end
  end

  private

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
