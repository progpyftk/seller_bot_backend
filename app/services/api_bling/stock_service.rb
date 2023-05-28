# API KEY
# user: seller_bot
# API_KEY e50a0c2687805c4dcd13666d1b1ed7acea38c5250ffe7d972b7955097031aba93bb6d51a

module ApiBling
  class StockService < ApplicationService
    def initialize
      @apikey = ENV['BLING_API_KEY']
    end

    def call
      update_stock_database
    end

    def update_stock_database
      skus = read_api
      skus.each do |sku, quantity|
        product = Stock.find_or_initialize_by(sku: sku)
        product.sku = sku
        product.quantity = quantity
        product.save
      end
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