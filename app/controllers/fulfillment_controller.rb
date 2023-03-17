require_relative '../services/db_populate/update_items_table_service'

class FulfillmentController < ApplicationController
  def index

    # ATENÇÃO AQUI !! A CHAMADA DEVE SER FEITA PARA CADA SELLER, NÃO POSSO CHAMAR OS ANUNCIOS DE UM SELLER COM DE OUTRO
    # TEM QUE SER MODELADO DE ACORDO COM O SELLER !!

    # 1. Para cada seller pegar todos anúncios e depois no final fazer uma única lista e enviar para o frontend
    # a. ajeitar o serviço ApiMercadoLivre::FulfillmentPausedItems para que seja feito para cada seller
    # b. o ideal é o serviço já retornar tudo, vai ficar melhor
    resp = ApiMercadoLivre::FulfillmentPausedItems.call
    # gerar a lista das urls que deverão ser chamadas
    resp.each_slice(20) do |batch|
      puts '---- batch of 20 ----'
      url_prefix = "https://api.mercadolibre.com/items?ids="
      url_items_ids = ""
      url_attributes = "&attributes=price,title,logistic,permalink,seller_id,available_quantity,sold_quantity"
      puts batch
      batch.each do |item_id|
        url_items_ids("#{item_id},")
      end
    end

    # chamar as urls pela api


    render json: resp, status: 200

    """DbPopulate::UpdateItemsTableService.call
    items = Item.where(logistic_type: 'fulfillment').where(available_quantity: 0)
    @resp = []
    items.each do |item|
      hash1 = item.attributes
      hash1['seller_nickname'] = item.seller.nickname
      @resp << hash1
    end
    render json: @resp, status: 200"""
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
