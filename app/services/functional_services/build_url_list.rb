module FunctionalServices
    # retorna uma lista com várias urls em que cada uma contém os ids e attiburtes para uma chamada de multget
    class BuildUrlList  < ApplicationService
        def initialize(items_list, attributes)
          @items_list = items_list
          @attributes = attributes
          @urls_list = []
        end

        def call
            build_url_list
            @urls_list
        end

        def build_url_list
            @items_list.each_slice(20) do |url_items_ids|
                url_prefix = "https://api.mercadolibre.com/items?ids="
                url_final = url_prefix + url_items_ids.join(',') + "&attributes=#{@attributes.join(',')}"
                @urls_list.push(*url_final)
            end
            @urls_list
        end

    end
end