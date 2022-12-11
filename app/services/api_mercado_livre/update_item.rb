# ML Api
module ApiMercadoLivre
  # faz a leitura da api de um item especifico e atualiza na BD
  # se houver alguma alteração, chama a funcao que faz o trackrecord
  class UpdateItem < ApplicationService
    def initialize(item, seller)
      @seller = seller
      @item = item
    end

    def call
      update_item
    end

    def update_item
      puts 'galta'
    end
  end
end
