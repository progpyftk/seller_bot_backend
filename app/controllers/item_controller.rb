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
    puts 'Chamando a função fiscal_data'
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    puts 'Recebeu o post com as seguintes informações'
    pp item_params
    # Colocar aqui um teste que se não encontrar o anúncio, retornar que não encontrou
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemFiscalData.call(item))
      puts '--------- Response com JSON Parse -----------'
      pp resp
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end

  def general_data
    puts 'Chamando a função general_data'
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    puts 'Recebeu o post com as seguintes informações'
    pp item_params
    # Colocar aqui um teste que se não encontrar o anúncio, retornar que não encontrou
    begin
      resp = JSON.parse(ApiMercadoLivre::ItemGeneralData.call(item))
      puts '--------- Response com JSON Parse -----------'
      pp resp
      render json: resp, status: 200
    rescue RestClient::ExceptionWithResponse => e
      render json: e, status: 400
    end
  end


end
