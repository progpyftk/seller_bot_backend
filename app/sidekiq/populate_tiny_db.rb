class PopulateTinyDb
    include Sidekiq::Job
  
    def perform
      # Primeiramente faz leitura de todos os skus e ids.
      # atualiza a BD com o estoque atual
      tiny = ApiTiny::TinyApiService.new()
      begin
        tiny.build_and_update_estoque_db
        tiny.atualiza_quantidade_por_id
        return 200
      rescue RestClient::ExceptionWithResponse => e
        puts e.response
        return 400
      end
    end
    
  end
  