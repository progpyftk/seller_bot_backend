
class FulfillmentController < ApplicationController
  before_action :authenticate_user!
  def index
    @items = []
    current_user.sellers.each do |seller|
      seller_items_ids = []
      seller_items_data = []
      puts seller.nickname
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }
      url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?logistic_type=fulfillment&labels=without_stock"
      resp = JSON.parse(RestClient.get(url, auth_header))
      # esse resp nos trás apenas os items_ids, vamos ter que fazer um multget para pega-los
      # pode ser que não tenha nenhum anuncio sem estoque no full
      pp resp['results']
      puts resp['results'].blank?
      puts resp['results']
      if resp['results'].blank?
        puts 'Parabéns, não há anúncios sem estoque no full!'
        seller_items_ids = []
      else
        puts 'Há anúncios no full sem estoque'
        seller_items_ids = resp['results']
        pp seller_items_ids
        # tambem temos que verificar se TEM UM SCROLL_ID
        if resp['scroll_id'].blank?
           # entao temos menos 20 resultados e não é necessário scroll_id
          puts 'não precisa de scroll_id'
        else
          puts 'precisa de scroll_id'
          url = "https://api.mercadolibre.com/users/#{@seller.ml_seller_id}/items/search?logistic_type=fulfillment&labels=without_stock&search_type=scan&scroll_id=#{resp['scroll_id']}&limit=100"
          until resp['results'].blank?
            resp = JSON.parse(RestClient.get(url, auth_header))
            seller_items_ids.push(*resp['results'])
          end
        end
        
      end
      pp seller_items_ids
      # aqui já vamos pegar os dados de cada anúncio do seller
      seller_items_data = ApiMercadoLivre::FetchAllItemsDataBySeller.call(seller, seller_items_ids)
      pp seller_items_data
      @items.push(seller_items_data)
    end
    # até aqui, está tudo funcionando, agora é só tratar esse resultado e mandar pro front!
    pp @items

    #items = Item.includes(:seller).where(logistic_type: 'fulfillment', available_quantity: 0)
    #item_without_stock_at_fullfilment = items.map { |item| item.attributes.merge(seller_nickname: item.seller.nickname) }
    render json: @items, status: 200
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
    item_params = params.require(:item).permit(:ml_item_id)
    item = Item.find(item_params[:ml_item_id])
    resposta = ApiMercadoLivre::FlexTurnOff.call(item)
    render json: resposta, status: 200
  end

  def to_increase_stock_api
    puts ' ---- testando funções de leitura da API -----'
    # preciso saber quais são os available_filters
    # filtrar na API do mercadolivre todos anúncios que estão no Full e sem estoque
    current_user.sellers.each do |seller|
      #uth_header = { 'Authorization' => "Bearer #{seller.access_token}" }
      #url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?logistic_type=fulfillment$labels=without_stock"
      #resp = JSON.parse(RestClient.get(url, auth_header))
      #Rails.logger.info (pp resp)
      #Rails.logger.info (puts)
      #pp resp
      #url = "https://api.mercadolibre.com/sites/MLB/search?seller_id=#{seller.ml_seller_id}&logistic_type=fulfillment"
      #resp = JSON.parse(RestClient.get(url))
      #Rails.logger.info (pp resp)
      #Rails.logger.info (puts)
      #pp resp
      # anuncios com FULL + FLEX
      auth_header = { 'Authorization' => "Bearer #{seller.access_token}" }
      
      # separamos os anuncios que estao com flex ligado
      url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?logistic_type=fulfillment&shipping_tags=self_service_in"
      resp = JSON.parse(RestClient.get(url, auth_header))
      Rails.logger.info (pp resp)
      Rails.logger.info (puts)
      pp resp
      # anuncios que estao com flex desligado
      url = "https://api.mercadolibre.com/users/#{seller.ml_seller_id}/items/search?logistic_type=fulfillment&shipping_tags=self_service_out"
      resp = JSON.parse(RestClient.get(url, auth_header))
      Rails.logger.info (pp resp)
      Rails.logger.info (puts)
      pp resp      
      # analisamos cada um desses anuncios para ver quais tem variação e quais nao tem
      # analiamos o sku de acordo com o sku do erp
    end
    render json: [], status: 200
  end


end
