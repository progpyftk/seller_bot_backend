
class FulfillmentController < ApplicationController
  def index
    items = Item.includes(:seller).where(logistic_type: 'fulfillment', available_quantity: 0)
    item_without_stock_at_fullfilment = items.map { |item| item.attributes.merge(seller_nickname: item.seller.nickname) }
    render json: item_without_stock_at_fullfilment, status: 200
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
    stock = Stock.find_by(sku: sku)
    if stock.nil?
      puts "Stock not found for SKU: #{sku}"
      return 0
    end
    stock.quantity
  end

  def flex
    # atualiza a BD de estoques com o Bling
    ApiBling::StockService.call
  
    items_full = Item.where(logistic_type: 'fulfillment')
    @linhas_tabela = items_full.flat_map do |item|
      if item.variations.present?
        item.variations.each_with_object([]) do |item_variation, result|
          next unless item_variation.sku.present?
  
          result << {
            ml_item_id: item_variation.item_id,
            variation_id: item_variation.variation_id,
            variation: true,
            seller_nickname: item.seller.nickname,
            link: item.permalink,
            sku: item_variation.sku,
            quantity: get_sku_qtt(item_variation.sku),
            flex: item.flex
          }
        end
      else
        {
          ml_item_id: item.ml_item_id,
          variation_id: nil,
          variation: false,
          seller_nickname: item.seller.nickname,
          link: item.permalink,
          sku: item.sku,
          quantity: get_sku_qtt(item.sku),
          flex: item.flex
        }
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
