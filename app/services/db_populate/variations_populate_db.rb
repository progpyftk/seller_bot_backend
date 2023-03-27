# ML Api
module DbPopulate
    # faz o update da tabela de variações, necessita de ter a tabela Items populada.
    # utiliza a busca dos dados fiscais para esse serviço
    class VariationsPopulateDb < ApplicationService
        def call
        update_variations_table
        end

        def update_variations_table
        Item.all.each do |item|
            begin
                parsed_fiscal_data = JSON.parse(ApiMercadoLivre::ItemFiscalData.call(item))
                pp parsed_fiscal_data
                # necessário separar as variações
                variations = parsed_fiscal_data['variations']
                variations.each do |variation|
                    item_id = parsed_fiscal_data['item_id']
                    id = variation['id']
                    sku = variation['sku']['sku']
                    ncm = variation['sku']['tax_information']['ncm']
                    ean = variation['sku']['tax_information']['ean']
                    puts item_id
                    puts id
                    puts sku
                    puts ncm
                    puts ean
                    item.variations.create(attributes)
                end
                rescue RestClient::ExceptionWithResponse => e
                puts e
                puts 'deu algum erro'
                end
            end
        end
    end
end
  