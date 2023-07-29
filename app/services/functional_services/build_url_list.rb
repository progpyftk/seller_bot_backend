module FunctionalServices
    # retorna uma lista com várias urls em que cada uma contém os ids e attributes para uma chamada de multget
    class BuildUrlList  < ApplicationService
        def initialize(items_list, attributes = [])
          @items_list = items_list
          @attributes = attributes
          @urls_list = []
        end
        
        def call
            puts "*** Iniciando: FunctionalServices::BuildUrlList *** "
            build_url_list
            puts "*** Finalizando: FunctionalServices::BuildUrlList *** "
            @urls_list
        end

        def build_url_list
            @items_list.each_slice(20) do |url_items_ids|
                url_prefix = "https://api.mercadolibre.com/items?ids="
                url_final = url_prefix + url_items_ids.join(',') + "&include_attributes=all"
                @urls_list.push(*url_final)
            end
            @urls_list
        end

        def old_build_url_list
            @items_list.each_slice(20) do |url_items_ids|
                url_prefix = "https://api.mercadolibre.com/items?ids="
                if not @attributes.blank?
                    url_final = url_prefix + url_items_ids.join(',') + "&include_attributes=all   #attributes=#{@attributes.join(',')}"
                else
                    url_final = url_prefix + url_items_ids.join(',')
                end
                @urls_list.push(*url_final)
            end
            @urls_list
        end

    end
end