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

  def flex
    items_full = Item.where(logistic_type: 'fulfillment')
    items_full.each do |item|
      # para cada anuncio do full, verifica se tem variacoes
      if item.variations.present?
        pp item.variations
        item.variations.each do |item_variation|
          next if item_variation.sku.nil?

          puts 'o anúncio possui variação e tem SKU cadastrado na variação'
          # verifica no estoque físico a quantidade desse sku
          stock_sku = Stock.find_by(sku: item_variation.sku)
          puts stock_sku.quantity
        end
      else
        # vamos utilizar o sku do proprio anuncio
        puts 'o anúncio possui variação MAS NÃO TEM SKU cadastrado na variação'
        begin
          stock_sku = Stock.find_by(sku: item.sku)
          if stock_sku.nil?
            puts "naõ encontrou o SKU #{item.sku} no BLING" 
          end
          puts '-----------------'
          puts stock_sku
          puts stock_sku.quantity
        rescue ActiveRecord::RecordNotFound
          puts 'não encontrou o SKU na tabela de estoque'
          puts item.sku
        end
        puts item.sku
        puts stock_sku.quantity
      end
    end
  end
end
