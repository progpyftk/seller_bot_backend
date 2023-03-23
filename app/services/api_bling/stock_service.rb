# API KEY
# user: seller_bot
# API_KEY be9104a76acbdd68d12f01cd58a378609b076375d5ded1aca7e1cb223b12d3c171fe0c1e

module ApiBling
  class StockService < ApplicationService
    def initialize
      @apikey = ENV['BLING_API_KEY']
    end

    def call
      read_api
    end

    def read_api
      page = 1
      response = true
      sku_list = {}
      while response != false
        response = get_page_response(page)
        sku_list.merge!(response) unless response == false
        page += 1
      end
      sku_list
    end

    def get_page_response(page)
      sku_list = {}
      url = "https://bling.com.br/Api/v2/produtos/page=#{page}/json/"
      begin
        response = RestClient.get url, { params: { 'apikey' => @apikey, 'estoque' => 'S' } }
        if JSON.parse(response)['retorno']['erros']
          sku_list = false
        else
          JSON.parse(response)['retorno']['produtos'].each do |produto|
            sku_list[produto['produto']['codigo']] = produto['produto']['estoqueAtual']
          end
        end
      rescue RestClient::ExceptionWithResponse => e
        e.response
      end
      sku_list
    end
  end
end