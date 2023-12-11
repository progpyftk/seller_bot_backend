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

  def change_to_free_shipping
    item_params = params.require(:item).permit(:ml_item_id, :seller_id)
    puts "Recebendo dados do anúncio #{item_params[:ml_item_id]}, #{item_params[:seller_id]}"
    item = item_params[:ml_item_id]
    seller = Seller.find_by(nickname: item_params[:seller_id])
    begin
      resp = ApiMercadoLivre::ChangeFreeShipping.call(seller, item)
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
      resp2 = JSON.parse(ApiMercadoLivre::WinThePrice.call(item_params[:ml_item_id]))

      # Render the general data as JSON for the response with status 200.
      render json: resp2, status: 200
    rescue RestClient::ExceptionWithResponse => e
      # In case of an error from the external API request, render the error response as JSON with status 400.
      render json: e, status: 400
    end
  end

  def free_shipping
    items = []
    Seller.all.each do |seller|
      puts "--- Iniciando tratamento do frete grátis -- #{seller.nickname}"
      # dados para chamada
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }
      # vamos testar 3 chamadas diferentes
      # usando sitesra
      url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{seller.ml_seller_id}&price=0-78.99&shipping_cost=free"
      resposta = JSON.parse(RestClient.get(url, auth_header))
      if resposta['results'].present?
        items.push(*resposta['results'])
        offset = 50
        while resposta['results'].present?
          url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{seller.ml_seller_id}&price=0-78.99&shipping_cost=free&offset=#{offset}"
          resposta = JSON.parse(RestClient.get(url, auth_header))
          offset += 50
          items.push(*resposta['results'])
        end
      end
    end

    puts "a API do ML retornou #{items.length} resultados"
    parsed_items = parse_items_data(items)
    parsed_items.each do |item|
      puts 'desligando frete gratis'
      puts item[:seller_id]
      puts item[:ml_item_id]
      seller = Seller.find_by(ml_seller_id: item[:seller_id])
      ApiMercadoLivre::ChangeFreeShipping.call(seller, item[:ml_item_id])
    end

    render json: parsed_items, status: 200
  end

  private

  # Parse item data for a seller and return an array of parsed items
  def parse_items_data(items_data)
    filtered_items = items_data.reject do |item_data|
      puts 'removed an item'
      item_data['shipping']['free_shipping'] == false
    end
    parsed_items = filtered_items.map do |item_data|
      {
        ml_item_id: item_data['id'],
        seller_id: item_data['seller']['id'],
        title: item_data['title'],
        permalink: item_data['permalink'],
        price: item_data['price'],
        available_quantity: item_data['available_quantity'],
        sold_quantity: item_data['sold_quantity'],
        logistic_type: item_data['shipping']['logistic_type']
      }
    end
    parsed_items
  end





end
