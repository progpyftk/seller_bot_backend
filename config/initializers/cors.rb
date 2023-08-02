Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://sellerbot.com.br', 'http://api.sellerbot.com.br',  'sellerbot.com.br', 'api.sellerbot.com.br', '*'

    resource(
       '*', 
       headers: :any, 
       methods: [:get, :patch, :put, :delete, :post, :options, :show],
       expose: ['access-token', 'expiry', 'token-type', 'Authorization', 'uid', 'client'],
    )
  end
end

# For production, use the URL of your production frontend app.
