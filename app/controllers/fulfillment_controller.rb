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
    item_data = {
      ml_item_id: "",
      variation: "",
      variation_id: "",
      local_quantity: "",
      flex: "",
      permalink: "",
  }
    @fulfillment_items = []
    @items = []
    Seller.all.each do |seller|
      puts "------ #{seller.nickname} -------"
      @fulfillment_items = ApiMercadoLivre::FulfillmentActiveItems.call(seller)
      url_list = FunctionalServices::BuildUrlList.call(@fulfillment_items) # aqui poderia ter selecionado os atributos
      @items.push(*ApiMercadoLivre::ReadApiFromUrl.call(seller, url_list))
      @items.each do |item|
        puts item['body']['id']
        if item['body']['variations'].present?
          # chamamos os dados fiscais, pois é certo de ter o sku nos anúncios do fulfillment
          item_fiscal_data = ApiMercadoLivre::ItemFiscalData.call(item)
          item_fiscal_data['variations'].each do |variation|
            puts variation['id']
            puts variation['sku']['sku']
          end
          # montar a linha para cada variação
        else
          sku = sku_item_without_variation(item)
          # montar a linha
        end
        # para cada uma das linhas, procurar na api do bling a quantidade física disponível (que virá do bling de acordo com o SKU dessa tabela)
      end
    end
    render json: @items_list, status: 200
  end

  # ITEMS SEM VARIAÇÃO - buscar na API principal, se não encontrar, buscar na API de dados fiscais
  def sku_item_without_variation(item)
    @sku = nil
    if item['body']['seller_custom_field'].blank?
      item['body']['attributes'].each do |attribute|
        if attribute['id'] == 'SELLER_SKU'
          @sku = attribute['value_name']
        end
      end
    else
      @sku = item['body']['seller_custom_field']
    end
    if @sku.nil?
      item_fiscal_data = ApiMercadoLivre::ItemFiscalData.call(item)
    end
    @sku
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
