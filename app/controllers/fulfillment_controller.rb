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
    @sku_list = ApiBling::StockService.call
    @linhas_tabela = []
    #@linhas_tabela.push({:ml_item_id=>"MLB3175038821", :seller_nickname=>"Bluevix", :variation=>true, :variation_id=>"XXXXXXX", :quantity=>9999, :flex=>"Ligado", :link=>"https://produto.mercadolivre.com.br/MLB-3175038821-fonte-carregador-para-notebook-acer-n17908-65w-_JM", :sku=>"FONTE-ACER-65W"})
    @fulfillment_items = []
    @items = []
    Seller.all.each do |seller|
      @fulfillment_items = ApiMercadoLivre::FulfillmentActiveItems.call(seller)
      url_list = FunctionalServices::BuildUrlList.call(@fulfillment_items, ['id','seller_id' ,'variations', 'shipping', 'permalink', 'seller_custom_field', 'attributes']) # aqui poderia ter selecionado os atributos
      @items.push(*ApiMercadoLivre::ReadApiFromUrl.call(seller, url_list))
    end
    @items.each do |item|
      if item['body']['variations'].present?
        item_fiscal_data = ApiMercadoLivre::ItemFiscalData.call(item['body']['id'])
        if not item_fiscal_data.blank?
          item_fiscal_data['variations'].each do |variation|
            quantity = @sku_list[variation['sku']['sku']]
            if @linhas_tabela.select {|linha| linha[:ml_item_id] == item['body']['id'] }.empty? # ainda não tem o MLB, pode inserir a linha
              @linhas_tabela.push(line_attributes(item, variation['sku']['sku'], quantity, variation['id'], true))
            else # já existe esse MLB, vamos comparar a quantidade das variações
              linha_ja_existe = @linhas_tabela.select {|linha| linha[:ml_item_id] == item['body']['id'] }
              if linha_ja_existe[0][:quantity] < quantity # verifica se a que ja existe tem mais ou menos no estoque
                # nao insere a linha
              else # se a variacao atual tem menos, então vamos retirar a linha da variacao com mais unidade e colocar dessa que tem menos
                @linhas_tabela.delete_if { |h| h[:ml_item_id] == linha_ja_existe[0][:ml_item_id]}
                @linhas_tabela.push(line_attributes(item, variation['sku']['sku'], quantity, variation['id'], true))
              end
            end
          end
        end
      else
        sku = sku_item_without_variation(item)        
        quantity = @sku_list[sku]
        @linhas_tabela.push(line_attributes(item, sku, quantity,nil, false))
      end
    end
    @linhas_tabela    
    render json: @linhas_tabela, status: 200
  end

  def line_attributes(item, sku, quantity,variation_id, variation)
    item['body']['shipping']['tags'].include?('self_service_in') ? flex="Ligado" : flex="Desligado"
    {
      ml_item_id: item['body']['id'],
      seller_nickname: Seller.find_by(ml_seller_id: item['body']['seller_id']).nickname,
      variation: variation,
      variation_id: variation_id,
      quantity: quantity,
      flex: flex,
      link: item['body']['permalink'],
      sku: sku,
    }
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
    item_params = params.require(:item).permit(:ml_item_id)
    resposta = ApiMercadoLivre::FlexTurnOff.call(item_params[:ml_item_id])
    render json: resposta, status: 200
  end

end
