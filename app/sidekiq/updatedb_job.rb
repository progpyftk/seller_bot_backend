class UpdatedbJob
    include Sidekiq::Job
  
    def perform
      puts '---- Iniciando atualização da DB pelo sidekiq ----'
      begin
        puts 'iniciando a atualização completa da base de dados'
        DbPopulate::CreateItemsTableService.call
        return 200
      rescue RestClient::ExceptionWithResponse => e
        puts e.response
        return 400
      end
    end
    
  end
  