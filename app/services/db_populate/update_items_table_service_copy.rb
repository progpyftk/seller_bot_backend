# ML Api
module DbPopulate
  # faz o update da base de dado de acordo com a API do ML
  class UpdateItemsTableService < ApplicationService
    def call
      # puts 'calling DbPopulate::UpdateItemsTableService'
      all_sellers
    end

    def all_sellers
      Seller.all.each do |seller|
        # Rails.logger.info "hello, it's #{Time.now}"
        # Rails.logger.info "Seller: #{seller.nickname} Status: #{seller.auth_status}"
        # puts 'sellers'
        # puts seller.nickname
        # puts seller.auth_status
        # next unless seller.auth_status == '200'
        next unless seller.auth_status == '200'

        # pega a lista completa de todos anuncios do vendedor no ML
        puts "pegando a lista completa do seller #{Time.now}"
        items_ids = ApiMercadoLivre::AllSellerItemsService.call(seller)
        puts "terminou de pegar a lista de MLB do seller #{Time.now}"
        # puts 'numero de anuncios do seller'
        # puts items_ids.length
        # pega os dados de cada um desses anuncios
        puts "pega os dados de todos esses MLB #{Time.now}"
        all_items_raw = ApiMercadoLivre::ItemMultigetDataService.call(items_ids, seller)
        puts "terminou de pegar os dados de todos anuncios desse seller #{Time.now}"
        # puts 'numero de anuncios com os dados dos seller'
        # puts all_items_raw.length
        # para cada anuncio, atualiza a base de dados, cria se for novo ou atualiza se algo mudou
        puts "grava na DB #{Time.now}"
        all_items_raw.each do |parsed_item|
          # pp parsed_item if parsed_item['body']['id'] == 'MLB1800883230'

          if parsed_item.nil?
            puts 'encontrou um parsed_item NIL'
            # Rails.logger.info "hello, it's #{Time.now}"
            # Rails.logger.info 'encontrou um parsed_item NIL}'
          end
          populate_db(parsed_item, seller)
        end
        puts "terminou de gravar na DB #{Time.now}"
      end
      puts "---- INICIA OUTRO SELLER ---- #{Time.now}"
    end

    def populate_db(parsed_item, seller)
      # seleciona apenas os atributos desejados para colocar na BD
      attributes = item_attributes(parsed_item)
      begin
        # tenta atualizar o anuncio, mas se ele nao existe, cria um novo
        item = Item.find(attributes[:ml_item_id])
        item.update(attributes)
        # ActiveModel::Dirty previous_changes() public
        # retorna um hash com tudo que foi alterado, antes de salvar
        updates_hash = item.previous_changes
        # faz o eventTrack, tratanto justamente esse hash que tras as mudancas
        unless item.previous_changes.empty?
          # puts "atualizando o anuncio #{item.ml_item_id}"
          # Rails.logger.info "hello, it's #{Time.now}"
          # Rails.logger.info "Atualizando o anuncio #{item.ml_item_id}"
          DbPopulate::UpdateEventTrackService.call(item, updates_hash)
        end

        # no ML mesmo que o item seja simples, ele ainda assim possui um atributo chamado variations, que
        # possui por sua ver um id e um sku para cada variacao,as vezes esse sku pode ser null, ou podemos ter mais
        # de uma variacao, contendo assim mais de um sku. É importante monitorar esses sku para desligar o flex dos anuncios que
        # estao no full, especificamente no caso daqueles que possuem variacoes, pois se uma delas acabar, precisamos desligar.
        # verifica se o produtos tem o atributo variacao
        if parsed_item['body']['variations'].present?
          # atualiza a tabela de variacoes
          parsed_item['body']['variations'].each do |variation|
            next if variation['seller_custom_field'].nil?

            puts "Id da Variacao: #{variation['id']} Sku da Variação: #{variation['seller_custom_field']}"
            # atualiza e se não existir cria
            variation = Variation.find_or_initialize_by(variation_id: variation['id'])
            variation.variation_id = variation['id']
            variation.sku = variation['seller_custom_field']
            variation.ml_item_id = parsed_item['body']['id']
            variation.save
          end
        end
      end
    rescue ActiveRecord::RecordNotFound
      # puts 'rescue ActiveRecord::RecordNotFound - cria o anuncio na db'
      # Rails.logger.info "hello, it's #{Time.now}"
      # Rails.logger.info 'rescue ActiveRecord::RecordNotFound - Criando anuncio na db'
      seller.items.create(attributes)
      nil
    end
  end

  def item_attributes(parsed_item)
    if parsed_item['body']['id'] == "MLB2879832085"
      puts 'entrei aqui'
      pp parsed_item
    end
    {
      ml_item_id: parsed_item['body']['id'],
      title: parsed_item['body']['title'],
      permalink: parsed_item['body']['permalink'],
      price: parsed_item['body']['price'],
      base_price: parsed_item['body']['base_price'],
      available_quantity: parsed_item['body']['available_quantity'],
      sold_quantity: parsed_item['body']['sold_quantity'],
      logistic_type: parsed_item['body']['shipping']['logistic_type'],
      free_shipping: parsed_item['body']['shipping']['free_shipping'],
      sku: parsed_item['body']['seller_custom_field']
    }
  rescue StandardError => e
    # puts e
    # puts '=====---- deu algum erro no parsed ----====='
    # puts 'é esse abaixo'
    # pp parsed_item
    # Rails.logger.info "hello, it's #{Time.now}"
    # Rails.logger.info e
    # Rails.logger.info parsed_item['body']['id']
    # Rails.logger.info '=====---- deu algum erro no parsed ----====='
  end
end
