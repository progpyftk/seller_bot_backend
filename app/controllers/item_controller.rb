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
    items = Item.includes(:seller).where(free_shipping: true, price: 0..78.99)
    free_shipping_items = items.map { |item| item.attributes.merge(seller_nickname: item.seller.nickname) }
    render json: free_shipping_items , status: 200
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
