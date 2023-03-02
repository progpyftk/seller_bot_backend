# ML Api
module ApiMercadoLivre
  # faz a leitura da api de um item especifico e atualiza na BD
  # se houver alguma alteração, chama a funcao que faz o trackrecord
  class UpdateItem < ApplicationService
    def initialize(item)
      @item = item
    end

    def call
      update_item
    end

    def update_item
      # ler os atributos do item no ML
      # atualizar a DB
      # verificar quais foram alterados e fazer o trackrecord
      puts 'falta'
    end
  end
end
