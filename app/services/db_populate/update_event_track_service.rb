require 'rest-client'
require 'json'
require 'pp'

module DbPopulate
  # faz o update da base de dado de acordo com a API do ML
  # para cada update realizado esse servico salva em cada tabela especifica os dados alterados
  # ele identifica os attributos e salva na tabela correta
  # principais eventos
  # eventos de logistica - alteracao da forma de envio
  # alteracao de preco
  # alteracao do numero de vendas
  # alteracao do estoque de um produto
  class UpdateEventTrackService < ApplicationService
    def initialize(item, updates_hash)
      @updates_hash = updates_hash
      @item = item
    end

    def call
      update_events
    end

    def update_events
      update_logistics_events if @updates_hash.key?(:logistic_type)
      update_price_events if @updates_hash.key?(:price)
    end

    def update_logistics_events
      previous_value = @updates_hash[:logistic_type][0]
      new_value = @updates_hash[:logistic_type][1]
      updated_at = @updates_hash[:updated_at][0]
      @item.logistic_events.create(new_logistic: new_value,
                                   old_logistic: previous_value,
                                   change_time: updated_at)
    end

    def update_price_events
      previous_value = @updates_hash[:price][0]
      new_value = @updates_hash[:price][1]
      updated_at = @updates_hash[:updated_at][0]
      @item.price_events.create(new_price: new_value,
                                old_price: previous_value,
                                change_time: updated_at)
    end
  end
end
