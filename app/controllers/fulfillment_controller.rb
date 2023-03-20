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


  def flex
    @items_list = []
    @linhas_tabela = []
    Seller.all.each do |seller|
      @item_list = ApiMercadoLivre::FulfillmentActiveItems.call(seller)
    end
    # filtra os anúncios que estão no Fulfillmente
    # pega as informações de cada um desses anúncios
    # avaiable_quantiy
    # flex ligado ou desligado
    # verifica se o anúncio tem variação
    # se tiver, vamos pegar os dados fiscais, que retornará o sku de cada variação
    # se não tiver variação, o sku pode estar em dois campos: 
    # 1 - ['body']['seller_custom_field']
    # 2 - ['body']['attributes'] attribute['id'] == 'SELLER_SKU' attribute['value_name']
    # aqui teremos um array com todas as variações e anúncios e seus skus, dai em diante, basta comparar o sku de cada um com a api do bling


    render json: @items_list, status: 200
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
