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

  # Controller action to fetch items with free shipping and a price less than $80 from MercadoLibre API
  def free_shipping
    @items = fetch_items_with_free_shipping_and_low_price

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

  # Controller action to fetch fiscal data for a MercadoLibre item.
  def fiscal_data
    # Extract the required parameters from the request (specifically, the ml_item_id).
    item_params = params.require(:item).permit(:ml_item_id)

    begin
      # Call the external ApiMercadoLivre service to fetch fiscal data for the specified item.
      # The service takes the ml_item_id as a parameter and returns the fiscal data in JSON format.
      resp = JSON.parse(ApiMercadoLivre::ItemFiscalData.call(item_params[:ml_item_id]))

      # Render the fiscal data as JSON for the response with status 200.
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      # In case of an error from the external API request, render the error response as JSON with status 400.
      render json: e, status: 400
    end
  end

  
  # Controller action to fetch general data for a MercadoLibre item.
  def general_data
    # Extract the required parameters from the request (specifically, the ml_item_id).
    item_params = params.require(:item).permit(:ml_item_id)

    begin
      # Call the external ApiMercadoLivre service to fetch general data for the specified item.
      # The service takes the ml_item_id as a parameter and returns the general data in JSON format.
      resp = JSON.parse(ApiMercadoLivre::ItemGeneralData.call(item_params[:ml_item_id]))

      # Render the general data as JSON for the response with status 200.
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      # In case of an error from the external API request, render the error response as JSON with status 400.
      render json: e, status: 400
    end
  end

  private

  # Fetch items with free shipping and price less than $80 for all sellers associated with the current user
  def fetch_items_with_free_shipping_and_low_price
    items = []

    current_user.sellers.each do |seller|
      seller_items = fetch_seller_items_with_free_shipping_and_low_price(seller)
      items.concat(seller_items) unless seller_items.empty?
    end

    items
  end

  # Fetch seller items with free shipping and price less than $80
  def fetch_seller_items_with_free_shipping_and_low_price(seller)
    auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }

    # Build the MercadoLibre API URL for fetching seller items
    url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{seller.ml_seller_id}&price=0-79&shipping_cost=free" 

    # Fetch the API response for the URL with the given authorization header.
    resp = fetch_api_response(url, auth_header)

    # Return an empty array if there are no items for the seller.
    return [] if resp['results'].blank?

    parse_items_data(seller, resp['results'])
  end

  # Fetch the API response for the given URL and authorization header.
  # Handle any API request errors, and return an empty array in case of errors.
  def fetch_api_response(url, auth_header)
    JSON.parse(RestClient.get(url, auth_header))
  rescue StandardError => e
    puts "Error fetching data from API: #{e.message}"
    []
  end

  # Parse item data for a seller and return an array of parsed items
  def parse_items_data(seller, items_data)
    items_data.map do |item_data|
      {
        ml_item_id: item_data['id'],
        seller_id: seller.nickname,
        title: item_data['title'],
        permalink: item_data['permalink'],
        price: item_data['price'],
        available_quantity: item_data['available_quantity'],
        sold_quantity: item_data['sold_quantity'],
        logistic_type: item_data['shipping']['logistic_type']
      }
    end
  end
end
