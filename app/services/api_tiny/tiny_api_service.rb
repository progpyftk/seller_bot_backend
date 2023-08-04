require 'rest-client'

module ApiTiny
  class TinyApiService
    API_BASE_URL = 'https://api.tiny.com.br/api2'.freeze
    API_FORMAT = 'JSON'.freeze
    API_RATE_LIMIT = 50 # 60 requests per minute

    attr_reader :api_token

    def initialize()
      @api_token = ENV['TINY_API_TOKEN']
    end


	# Fetch all products from the Tiny API
	def fetch_all_products
		puts '--- Dados de Todos os Produtos ---'

		url = "#{API_BASE_URL}/produtos.pesquisa.php"
		params = { token: api_token, formato: API_FORMAT, pagina: 1 }
		all_products = []
		response = JSON.parse(RestClient.get(url, params: params))

		loop do
			puts '--- Chamando fetch_all_products para verificar a BD por completo ---'

			# Verifica se a resposta da API possui produtos
			if not response['retorno']['produtos'].blank?
				products = response['retorno']['produtos']
			else
				pp response
				puts 'Ocorreu algum erro na pesquisa da API do Tiny - Verificar'
				break
			end

			# Verifica se a busca ocorreu normalmente e se existem produtos na página
			if products.blank?
				break # Sai do loop se não houver mais produtos
			else
				all_products.push(*products)
				# Incrementa o número da página para buscar a próxima
				params[:pagina] += 1
				response = JSON.parse(RestClient.get(url, params: params))
			end
		end

		puts "Número de produtos cadastrados no Tiny que foram retornados: #{all_products.length}"
		all_products
	rescue RestClient::ExceptionWithResponse => e
		puts "Error fetching data from Tiny API: #{e.message}"
		[]
	end

  # Build and update the Estoque table with product data
	def build_and_update_estoque_db
		puts '--- build_and_update_estoque_db ---'
		# Fetch all products from the Tiny API
		produtos = fetch_all_products
		# Iterate through each product data and update the Estoque table
		if produtos.blank?
			return
		else
			produtos.each do |produto_data|
				puts "ID do Produto no Tiny: #{produto_data['produto']['id']}"
				# Find or initialize Estoque by id_produto
				estoque = Estoque.find_or_initialize_by(id_produto: produto_data['produto']['id'])
				# Update the SKU attribute with product data
				estoque.sku = produto_data['produto']['codigo']
				# Save the record in the database (only if it's new)
				estoque.save
				puts 'Produto adicionado/atualzado na tabela estoque.'
			end
		end
		# Print all records in the Estoque table for verification
		pp Estoque.all
	end


	# Update the quantity by product ID with API rate limit handling
	def atualiza_quantidade_por_id
		puts '--- Iniciando atualização das quantidades por ID ---'
			Estoque.all.each do |produto|
				data = fetch_product_data_by_id(produto.id_produto)
				pp data
				if data['retorno']['produto']['saldo'].blank?
					puts "não foi possível atualizar o produto #{produto.id_produto}"
				else
					produto.quantidade = data['retorno']['produto']['saldo']
					if produto.quantidade < 0
						produto.quantidade = 0
					end
					produto.save
					# Add a delay between API calls to comply with rate limit
				end				
				sleep(60.0 / API_RATE_LIMIT)
			end
    end


		# Fetch product data by its ID using the Tiny API
		def fetch_product_data_by_id(id_produto)
			url = "#{API_BASE_URL}/produto.obter.estoque.php"
			params = { token: api_token, formato: API_FORMAT, id: id_produto }
			response = JSON.parse(RestClient.get(url, headers(params)))
			puts '--- Dados do produto pelo seu id ---'
			puts "Id do produto: #{id_produto}"
			puts 'resposta da API'
			pp response
		end

		# List inventory updates within the last 5 minutes in São Paulo timezone
    def atualiza_estoques_alterados
			url = "https://api.tiny.com.br/api2/lista.atualizacoes.estoque"
			current_time = Time.current
			formatted_time = current_time.strftime('%d/%m/%Y')
		
			page = 1
			loop do
				params = { token: api_token, formato: JSON, dataAlteracao: formatted_time, pagina: page }
				response = RestClient.get(url, headers(params))
				data = JSON.parse(response)
		
				# If there are no more products to update, exit the loop
				break if data['retorno']['produtos'].blank?
		
				data['retorno']['produtos'].each do |product|
					puts 'adicionado dado na tabela Estoque'
		
					estoque = Estoque.find_or_initialize_by(sku: product['produto']['id'])
					estoque.quantidade = product['produto']['saldo']
					estoque.save
				end
		
				# Increment the page number for the next request
				page += 1
		
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
