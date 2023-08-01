module ApiTiny
	class TinyApiService
	# app/services/tiny_api_service.rb
		attr_reader :api_token

		def initialize()
			@api_token = 'ec2c1d35e4ee21f19f9f5eed9c52cc316bbdf193'
		end

		def fetch_products
			Estoque.all.each do |item|
				puts item.sku
				puts item.quantidade
			end
			
			url = "https://api.tiny.com.br/api2/lista.atualizacoes.estoque"
			# Obter a hora atual
			current_time = Time.current
			# Diminuir 1 minutos
			new_time = current_time - 1
			# Formatando a nova hora no formato dd/mm/yyyy hh:mm:ss
			formatted_time = new_time.strftime('%d/%m/%Y %H:%M:%S')
			puts formatted_time
			params = { token: api_token, formato:JSON, dataAlteracao: formatted_time  }
			response = RestClient.get(url, headers(params))
			data = JSON.parse(response)

			# se a busca ocorreu normalmente, devemos pegar os valores e atualizar na BD. 
			if data['retorno']['produtos'].blank?
				puts '*** API TINY **** '
				puts '*** NÃO HOUVE ATUALIZAÇÃO ***'
			else
				data['retorno']['produtos'].each do |product|
					puts 'adicionado dado na tabela Estoque'
					
					# Procura um registro com o SKU fornecido
					estoque = Estoque.find_or_initialize_by(sku: product['produto']['codigo'])
					
					# Define os atributos do registro
					estoque.quantidade = product['produto']['saldo']
					
					# Salva o registro no banco de dados (somente se ele é novo)
					estoque.save
				  end
			end
			rescue RestClient::ExceptionWithResponse => e
				puts "Error fetching data from Tiny API: #{e.message}"
				[]
		end

		private

		def headers(params = {})
			{ params: params }
		end
	end

end