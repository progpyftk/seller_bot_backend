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
end
