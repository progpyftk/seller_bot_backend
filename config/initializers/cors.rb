Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://lorenzosimonassi.gitlab.io'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

# For production, use the URL of your production frontend app.
Rails.application.config.hosts << "https://lorenzosimonassi.gitlab.io/"