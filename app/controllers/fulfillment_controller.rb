require_relative '../services/db_populate/update_items_table_service'

class FulfillmentController < ApplicationController
  def index
    @items = []
    Seller.all.each do |seller|
      items_list = ApiMercadoLivre::FulfillmentPausedItems.call(seller)
      attributes = ['id', 'price', 'title', 'shipping', 'permalink', 'seller_id', 'available_quantity', 'sold_quantity']
      url_list = FunctionalServices::BuildUrlList.call(items_list, attributes)
      @items.push(*ApiMercadoLivre::ReadApiFromUrl.call(seller, url_list))
    end
    @items.map! { |each_hash| each_hash['body'] }
    @items.map! do |hash|
      hash['ml_item_id'] = hash['id']
      hash['logistic_type'] = hash['shipping']['logistic_type']
      hash.delete('shipping')
      hash.delete('id')
      hash
    end
    render json: @items, status: 200
  end

  def get_sku_qtt(sku)
    begin
      sku = Stock.find(sku)
    rescue ActiveRecord::RecordNotFound => e
      sku = 'NAO-ENCONTRADO'
      return 0
    end
    sku.quantity
  end

  def flex
    @linhas_tabela = []
    items_full = Item.where(logistic_type: 'fulfillment')
    items_full.each do |item|
      flex_status = ApiMercadoLivre::FlexStatusCheck.call(item)
      # para cada anuncio do full, verifica se tem variacoes
      if item.variations.present?
        # para cada uma das variações, verifica seu SKU
        item.variations.each do |item_variation|
          if item_variation.sku.blank?
            puts ' ---- possui variação, MAS NÃO POSSUI SKU cadastrado na variação ----'
            puts item.ml_item_id
            puts item.sku
            puts get_sku_qtt(item.sku)
            puts '------------------------------------------------------------------'
            @linhas_tabela << {ml_item_id: item.ml_item_id,seller_nickname: item.seller.nickname, link: item.permalink, sku: item.sku, quantity: get_sku_qtt(item.sku), flex: flex_status }
            # aqui temos que pegar o sku geral do anúncio, como se não tivesse variação
          else
            puts '------ o anúncio possui variação e tem SKU cadastrado na variação -----'
            puts "ml_item_id: #{item_variation.item_id}"
            puts "sku: #{item_variation.sku}"
            qtt = get_sku_qtt(item_variation.sku)
            puts "quantidade do sku: #{qtt}"
            puts '------------------------------------------------------------------'
            @linhas_tabela << {ml_item_id: item_variation.item_id, seller_nickname: item.seller.nickname, link: item.permalink, sku: item_variation.sku, quantity: get_sku_qtt(item_variation.sku), flex: flex_status }

            # montar o dict para colocar no array
          end
        end
      # caso NÃO tenha variação
      else
        # vamos utilizar o sku do proprio anuncio
        puts '----  o anúncio NÃO tem variação, vamos usar o sku geral ----'
        puts item.sku
        puts get_sku_qtt(item.sku)
        puts '------------------------------------------------------------------'
        @linhas_tabela << {ml_item_id: item.ml_item_id, seller_nickname: item.seller.nickname, link: item.permalink, sku: item.sku, quantity: get_sku_qtt(item.sku), flex: flex_status }
      end
    end
    render json: @linhas_tabela, status: 200
  end

  def flex_turn_off
    puts 'RECEBENDO POST DO AXIOS CARALHO'
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    resposta = ApiMercadoLivre::FlexTurnOff.call(item)
    pp resposta
    render json: resposta, status: 200
  end

end
