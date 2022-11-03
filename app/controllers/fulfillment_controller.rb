require_relative '../services/db_populate/update_items_table_service'

class FulfillmentController < ApplicationController
  def index
    DbPopulate::UpdateItemsTableService.call
    items = Item.where(logistic_type: 'fulfillment').where(available_quantity: 0)
    @resp = []
    items.each do |item|
      hash1 = item.attributes
      hash1['seller_nickname'] = item.seller.nickname
      @resp << hash1
    end
    render json: @resp, status: 200
  end

  def to_increase_stock
    puts 'increase strock'
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
    #render json: items_without_stock, status: 200
  end
end
