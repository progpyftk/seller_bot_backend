require_relative '../services/api_mercado_livre/authentication_service'

class SellerController < ApplicationController
  before_action :authenticate_user!

  def index
    puts 'estou no index'
    puts current_user.email
    pp request.headers
    Seller.all.each do |seller|
      ApiMercadoLivre::AuthenticationService.call(seller)
    end
    @sellers = Seller.all
    render json: @sellers, status: 200
  end

  def auth_all
    responses = {}
    Seller.all.each do |seller|
      result = ApiMercadoLivre::AuthenticationService.call(seller)
      hash = JSON.parse(result.body)
      hash['code'] = result.code.to_s
      responses[seller.ml_seller_id] = hash
    end
    responses.to_json
    render json: responses, status: 200
  end

  def create
    puts '--- seller_controller: create()'
    puts "--- current_user: #{current_user}"
    seller_params = params.require(:seller).permit(:nickname, :code, :ml_seller_id)
    current_user.sellers.create(seller_params)

    begin
      puts '--- começando a criação ---'
      resp = current_user.sellers.create(seller_params)
      puts "--- response of creating seller ---"
      puts resp
      render json: resp, status: 200
    rescue ActiveRecord::RecordNotFound => e
      # puts 'ActiveRecord::RecordNotFound => e'
      render json: e, status: 400
    rescue ActiveRecord::ActiveRecordError => e
      # puts 'ActiveRecord::ActiveRecordError => e'
      render json: e, status: 400
    rescue StandardError => e
      render json: e, status: 400
    end
  end

  def edit
    puts '--- seller_controller  edit() ---'
    seller_params = params.require(:seller).permit(:nickname, :code,:ml_seller_id, :access_token,:refresh_token)
    begin
      seller = Seller.find(seller_params[:ml_seller_id])
      resp = seller.update(seller_params)
      render json: resp, status: 200
    rescue ActiveRecord::RecordNotFound
      puts 'ActiveRecord::RecordNotFound - nao encontrou o seller'
    rescue ActiveRecord::ActiveRecordError
      puts 'ActiveRecord::ActiveRecordError'
    end
  end

  def delete
    puts '--- seller_controller  delete() ---'
    seller_params = params.require(:seller).permit(:ml_seller_id)
    begin
      resp = Seller.destroy(seller_params[:ml_seller_id])
      render json: resp, status: 200
    rescue ActiveRecord::RecordNotFound
      # puts 'ActiveRecord::RecordNotFound - nao encontrou o seller'
    rescue ActiveRecord::ActiveRecordError
      # puts 'ActiveRecord::ActiveRecordError'
    end
  end

  def check_auth
    seller_params = params.require(:seller).permit(:ml_seller_id)
    seller = Seller.find_by(ml_seller_id: seller_params[:seller][:ml_seller_id])
    resp = ApiMercadoLivre::AuthenticationService.call(seller)
    render json: resp, status: resp.code
  end

  def active_items
    resp = ApiMercadoLivre::MultithreadActiveItems.call('Bluevix')
    render json: resp, status: 200
  end

  # monta a tabela de promocoes
  def promotions_table
    @items = []
    @table_list = []
    # aqui temos que filtrar apenas os sellers do user
    Seller.all.each do |seller|
      seller_promotions = ApiMercadoLivre::SellerPromotionsService.call(seller)
      seller_promotions['results'].each do |seller_promotion|
        parsed_item = {
          seller: seller.ml_seller_id,
          promotion_id: seller_promotion['id'],
          type: seller_promotion['type'],
          status: seller_promotion['status'],
          start_date: seller_promotion['start_date'],
          finish_date: seller_promotion['finish_date'],
          deadline_date: seller_promotion['deadline_date'],
          name: seller_promotion['name'],
          benefits: seller_promotion['benefits'],
        }
        @items.push(parsed_item)
      end
    end
    # vamos filtrar essa lista de promoções e verificar aquelas que possuem anúncios para ativar
    filtered_promotions = @items.select do |promo|
      promo[:status] == 'started' && ['DEAL', 'LIGHTNING', 'MARKETPLACE_CAMPAIGN'].include?(promo[:type])
    end

    # para cada uma dessas vamos verificar se possui pelo menos um anúncio
    filtered_promotions.each do |promotion|
      seller = Seller.find(promotion[:seller])
      if ApiMercadoLivre::PromotionItemsCheck.call(seller, promotion[:promotion_id], promotion[:type] )
        @table_list.push(promotion)
      end
    end

    pp @table_list

    render json: @table_list, status: 200
  end

  # informacoes da promocao no dialogo
  def promotion_dialog_data
    # Aqui funciona recebendo os parâmetros de um POST com os dados da promoção, porém ainda não vai ativar
    # Vamos pegar os dados da promoções, e depois, se o usuário quiser, ele vai ativar
    promotion_params = params.require(:promotion_data).permit(:promotion_id, :type, :seller)
    seller = Seller.find(promotion_params[:seller])
    # PromotionItemsCounterService - contar os itens e parar em 200, já seleciona os candidates
    items = ApiMercadoLivre::PromotionItemsService.call(seller, promotion_params[:promotion_id], promotion_params[:type], 150)
    puts items.length
    result = { total_items: items.length }
    render json: result.to_json, status: 200
  end

  def activate_promotion
    promotion_params = params.require(:promotion_data).permit(:promotion_id, :type, :seller)
    seller = Seller.find(promotion_params[:seller])
    result = ApiMercadoLivre::PromotionItemsActivator.call(seller, promotion_params[:type], promotion_params[:promotion_id])
    render json: result.to_json, status: 200
  end




end
