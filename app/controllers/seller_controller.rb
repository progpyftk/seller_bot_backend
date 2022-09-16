require_relative '../services/api_mercado_livre/authentication_service'

class SellerController < ApplicationController
  def index
    Seller.all.each do |seller|
      puts 'atualizando a pagina das contas'
      puts 'fazendo o loop de cada seller e chamando a funcao de autenticacao'
      ApiMercadoLivre::AuthenticationService.call(seller)
    end
    @sellers = Seller.all
    puts '---- relacao de todos os sellers ------'
    pp @sellers
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
    puts 'entrei no controller create'
    seller_params = params.require(:seller).permit(:nickname, :code, :ml_seller_id)
    puts 'parametros recebidos:'
    pp seller_params
    begin
      puts 'estou no begin'
      resp = Seller.create(seller_params)
      puts 'resp do begin - criou na base de dados'
      puts resp
      render json: resp, status: 200
    rescue ActiveRecord::RecordNotFound => e
      render json: e, status: 400
    rescue ActiveRecord::ActiveRecordError => e
      render json: e, status: 400
    rescue StandardError => e
      render json: e, status: 400
    end
  end

  def check_auth
    seller_params = params.require(:seller).permit(:ml_seller_id)
    seller = Seller.find_by(ml_seller_id: seller_params[:seller][:ml_seller_id])
    resp = ApiMercadoLivre::AuthenticationService.call(seller)
    render json: resp, status: resp.code
  end
end
