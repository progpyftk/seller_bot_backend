require 'rest-client'
require 'json'
require 'pp'

# ML Api
module ApiMercadoLivre
  # authentication service class
  class AuthenticationService < ApplicationService
    attr_accessor :seller

    def initialize(seller)
      @seller = seller
      @response = nil
    end

    def call
      if first_access?
        puts 'entrou no first_access'
        retrieve_first_access_tokens
      else
        puts 'entrou no auth_with_refresh_token'
        auth_with_refresh_token
      end
      @response
    end

    def first_access?
      @seller.access_token.nil?
    end

    # para funcionar é necessário que o code esteja correto na base de dados
    def retrieve_first_access_tokens
      headers = { 'content-type' => 'application/x-www-form-urlencoded', 'accept' => 'application/json' }
      url = 'https://api.mercadolibre.com/oauth/token'
      payload = {
        'grant_type' => 'authorization_code',
        'client_id' => ENV['ML_API_CLIENT_ID'],
        'client_secret' => ENV['ML_API_CLIENT_SECRET'],
        'code' => @seller.code,
        'redirect_uri' => 'https://localhost:3000'
      }.to_json
      begin
        @response = RestClient.post(url, payload, headers)
        save_tokens(@response)
      rescue RestClient::ExceptionWithResponse => e
        @seller.auth_status = e.response.code
        @seller.last_auth_at = DateTime.current
        @seller.save
        @response = e.response
      end
    end

    def auth_with_refresh_token
      headers = { 'content-type' => 'application/x-www-form-urlencoded', 'accept' => 'application/json' }
      url = 'https://api.mercadolibre.com/oauth/token'
      payload = {
        'grant_type' => 'refresh_token',
        'client_id' => ENV['ML_API_CLIENT_ID'],
        'client_secret' => ENV['ML_API_CLIENT_SECRET'],
        'refresh_token' => @seller.refresh_token
      }.to_json
      begin
        @response = RestClient.post(url, payload, headers)
        save_tokens(@response)
      rescue RestClient::ExceptionWithResponse => e
        save_tokens(@response)
        @response = e.response
      end
    end

    def save_tokens(response)
      if response.nil?
        puts 'não obteve resposta do RestClient'
      else
        parsed_response = JSON.parse(response)
        @seller.access_token = parsed_response['access_token']
        @seller.refresh_token = parsed_response['refresh_token']
        @seller.auth_status = response.code.to_s
        @seller.last_auth_at = DateTime.current
        @seller.save
      end
    end
  end
end
