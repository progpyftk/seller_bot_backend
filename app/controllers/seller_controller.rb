require_relative '../services/api_mercado_livre/authentication_service'

class SellerController < ApplicationController
  before_action :authenticate_user!
 
  def index
    puts '---- current user ----'
    puts current_user.email
    puts current_user.id

    IncrementCounter.perform_async()
    Seller.all.each do |seller|
      puts 'autenticando todos os sellers no controller seller_controller'
      ApiMercadoLivre::AuthenticationService.call(seller)
    end
    @sellers = Seller.all
    #render plain: "OK"
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
end
