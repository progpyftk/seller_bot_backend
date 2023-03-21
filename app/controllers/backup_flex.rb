def flex
    @items_list = []
    @linhas_tabela = []
    Seller.all.each do |seller|
      @item_list = ApiMercadoLivre::FulfillmentActiveItems.call(seller)
    end
    # filtra os anúncios que estão no Fulfillmente



    # pega as informações de cada um desses anúncios
    # avaiable_quantiy
    # flex ligado ou desligado
    
    # verifica se o anúncio tem variação
    # se tiver, vamos pegar os dados fiscais, que retornará o sku de cada variação
    # se não tiver variação, o sku pode estar em dois campos: 
    # 1 - ['body']['seller_custom_field']
    # 2 - ['body']['attributes'] attribute['id'] == 'SELLER_SKU' attribute['value_name']

    # aqui teremos um array com todas as variações e anúncios e seus skus, dai em diante, basta comparar o sku de cada um com a api do bling



    items_full = Item.where(logistic_type: 'fulfillment')
    items_full.each do |item|
      flex_status = ApiMercadoLivre::FlexStatusCheck.call(item)
      # para cada anuncio do full, verifica se tem variacoes
      if item.variations.present?
        # para cada uma das variações, verifica seu SKU
        item.variations.each do |item_variation|
          if item_variation.sku.blank?
            puts ' ---- possui variação, MAS NÃO POSSUI SKU cadastrado na variação ----'
            puts item.ml_item_id
            puts item.sku
            puts get_sku_qtt(item.sku)
            puts '------------------------------------------------------------------'
            @linhas_tabela << {ml_item_id: item.ml_item_id,seller_nickname: item.seller.nickname, link: item.permalink, sku: item.sku, quantity: get_sku_qtt(item.sku), flex: flex_status }
            # aqui temos que pegar o sku geral do anúncio, como se não tivesse variação
          else
            puts '------ o anúncio possui variação e tem SKU cadastrado na variação -----'
            puts "ml_item_id: #{item_variation.item_id}"
            puts "sku: #{item_variation.sku}"
            qtt = get_sku_qtt(item_variation.sku)
            puts "quantidade do sku: #{qtt}"
            puts '------------------------------------------------------------------'
            @linhas_tabela << {ml_item_id: item_variation.item_id, seller_nickname: item.seller.nickname, link: item.permalink, sku: item_variation.sku, quantity: get_sku_qtt(item_variation.sku), flex: flex_status }

            # montar o dict para colocar no array
          end
        end
      # caso NÃO tenha variação
      else
        # vamos utilizar o sku do proprio anuncio
        puts '----  o anúncio NÃO tem variação, vamos usar o sku geral ----'
        puts item.sku
        puts get_sku_qtt(item.sku)
        puts '------------------------------------------------------------------'
        @linhas_tabela << {ml_item_id: item.ml_item_id, seller_nickname: item.seller.nickname, link: item.permalink, sku: item.sku, quantity: get_sku_qtt(item.sku), flex: flex_status }
      end
    end
    render json: @linhas_tabela, status: 200
  end