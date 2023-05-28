require_relative '../services/api_mercado_livre/authentication_service'

class ItemController < ApplicationController
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

  def create
    seller_params = params.require(:seller).permit(:nickname, :code, :ml_seller_id)
    begin
      resp = Seller.create(seller_params)
      render json: resp, status: 200
    rescue ActiveRecord::RecordNotFound => e
      render json: e, status: 400
    rescue ActiveRecord::ActiveRecordError => e
      render json: e, status: 400
    rescue StandardError => e
      render json: e, status: 400
    end
  end

  def retrieve_item
    resp = ApiMercadoLivre::ItemDataService.call(ml_item_id, seller)
    render json: resp, status: 200
  end

  def price_events
    @resp = []
    PriceEvent.all.each do |event|
      hash1 = event.attributes
      hash1['permalink'] = event.item.permalink
      @resp << hash1
    end
    render json: @resp, status: 200
  end

  def logistic_events
    @resp = []
    LogisticEvent.all.each do |event|
      hash1 = event.attributes
      hash1['permalink'] = event.item.permalink
      @resp << hash1
    end
    render json: @resp, status: 200
  end

  def free_shipping
    @items = []
    Seller.all.each do |seller|
      puts "--------- #{seller.nickname} ----------"
      # aqui deveria filtrar também na API os com frete grátis, porém não consegui.
      items_list = ApiMercadoLivre::ActiveItems.call(seller)
      puts "----- Active Items: #{items_list.length}"
      attributes = ['id', 'price', 'title', 'shipping', 'permalink', 'seller_id']
      url_list = FunctionalServices::BuildUrlList.call(items_list, attributes)
      @items.push(*ApiMercadoLivre::ReadApiFromUrl.call(seller, url_list))
    end
    @items.delete_if { |h| h['body']['price'] > 79}
    @items.delete_if { |h| h['body']['shipping']['free_shipping'] == false}
    table = table_lines(@items)
    render json: table , status: 200
  end

  def table_lines(items)
    @lines = []
    items.each do |item|
      hash = {
        ml_item_id: item['body']['id'],
        title: item['body']['title'],
        seller: item['body']['seller_id'],
        price: item['body']['price'],
        link: item['body']['permalink'],
      }
      @lines.push(hash)
      pp @lines
    end
    @lines
    free_shipping_items = Item.where(free_shipping: true).where(price: 0..78.99)
    render json: free_shipping_items.to_json, status: 200
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
    puts 'estou aqui'
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemFiscalData.call(item_params[:ml_item_id]))
      puts resp
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      puts e
      puts resp
      puts e.response
      render json: e, status: 400
    end
  end

  def general_data
    item_params = params.require(:item).permit(:ml_item_id)
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemGeneralData.call(item_params[:ml_item_id]))
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      puts e.response
      render json: e, status: 400
    end
  end

  # atualização da base de dados de forma geral
  def update_database
    begin
      puts 'iniciando a atualização completa da base de dados'
      DbPopulate::CreateItemsTableService.call
      render json: {}, status: 200
    rescue RestClient::ExceptionWithResponse => e
      puts e.response
      render json: {}, status: 400
    end
  end


end
