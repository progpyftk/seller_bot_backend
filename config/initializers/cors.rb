Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*', headers: :any, methods: %i[get post]
  end
end

# For production, use the URL of your production frontend app.
