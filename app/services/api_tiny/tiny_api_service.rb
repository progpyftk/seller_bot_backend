require 'rest-client'

module ApiTiny
  class TinyApiService
    API_BASE_URL = 'https://api.tiny.com.br/api2'.freeze
    API_FORMAT = 'JSON'.freeze
    API_RATE_LIMIT = 60 # 60 requests per minute

    attr_reader :api_token

    def initialize()
      @api_token = ENV['TINY_API_TOKEN']
    end

    # Fetch product data by its ID using the Tiny API
    def fetch_product_data_by_id(id_produto)
      puts '--- Dados do produto pelo seu id ---'
      url = "#{API_BASE_URL}/produto.obter.estoque.php"
      params = { token: api_token, formato: API_FORMAT, id: id_produto }
      response = JSON.parse(RestClient.get(url, headers(params)))
    end

    # Fetch data of all products using the Tiny API
    def fetch_all_products
			puts '--- Dados de Todos os Produtos ---'
			url = "#{API_BASE_URL}/produtos.pesquisa.php"
			params = { token: api_token, formato: API_FORMAT, pagina: 1 }
			all_products = []
		
			loop do
				puts '--- chamando fetch_all_products para verificar a BD por completo ---'
				response = JSON.parse(RestClient.get(url, headers(params)))
				products = response['retorno']['produtos']
				puts 'estou na pagina'
				puts params[:pagina]
				puts 'quantiade de produtos'
		
				# Verifica se a busca ocorreu normalmente e se existem produtos na página
				if products.blank?
					puts '*** API TINY **** '
					puts '*** NÃO HOUVE MAIS PRODUTOS ***'
					break # Sai do loop se não houver mais produtos
				else
					all_products.push(*products)
		
					# Incrementa o número da página para buscar a próxima
					params[:pagina] += 1
				end
		
			end
			all_products
		rescue RestClient::ExceptionWithResponse => e
			puts "Error fetching data from Tiny API: #{e.message}"
			[]
		end
		

  # Build and update the Estoque table with product data
	def build_and_update_estoque_db
		puts '--- Iniciando atualização da tabela Estoque com dados do Tiny ---'

		# Fetch all products from the Tiny API
		produtos = fetch_all_products

		# Iterate through each product data and update the Estoque table
		produtos.each do |produto_data|

			puts 'Adicionado dado na tabela Estoque'

			# Find or initialize Estoque by id_produto
			estoque = Estoque.find_or_initialize_by(id_produto: produto_data['produto']['id'])

			# Update the SKU attribute with product data
			estoque.sku = produto_data['produto']['codigo']

			# Save the record in the database (only if it's new)
			estoque.save
		end

		# Print all records in the Estoque table for verification
		pp Estoque.all
	end


    # Update the quantity by product ID with API rate limit handling
    def atualiza_quantidade_por_id
      puts '--- Iniciando atualização das quantidades por ID ---'
      puts "--- Limite de requisições por minuto: #{API_RATE_LIMIT} ---"
      Estoque.all.each do |produto|
				
        data = fetch_product_data_by_id(produto.id_produto)
        pp data
        produto.quantidade = data['retorno']['produto']['saldo']
        produto.save

        # Add a delay between API calls to comply with rate limit
        sleep(60.0 / API_RATE_LIMIT)
      end
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
