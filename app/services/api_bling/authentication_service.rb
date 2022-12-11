# API KEY
# user: seller_bot
# API_KEY e50a0c2687805c4dcd13666d1b1ed7acea38c5250ffe7d972b7955097031aba93bb6d51a

module Bling
  class AuthenticationService < ApplicationService
    def initialize
      # puts 'a'
    end

    def call
      authenticate
    end

    def authenticate
      response = RestClient.get 'https://bling.com.br/Api/v2/produtos/json/', { params: { 'apikey' => 'e50a0c2687805c4dcd13666d1b1ed7acea38c5250ffe7d972b7955097031aba93bb6d51a', 'estoque' => 'S' } }
      # puts JSON.parse(response).keys
      # puts JSON.parse(response).length
      # puts JSON.parse(response)['retorno']['produtos'].class
      # puts JSON.parse(response)['retorno']['produtos'].length
      JSON.parse(response)['retorno']['produtos'].each do |produto|
        # puts "SKU: #{produto['produto']['codigo']} -- Estoque: #{produto['produto']['estoqueAtual']}"
      end
    rescue RestClient::ExceptionWithResponse => e
      # puts e.response
      e.response
    end
  end
end

# puts 'estou aqui'
Bling::AuthenticationService.call
