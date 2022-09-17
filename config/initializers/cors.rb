Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '/cors',
      :headers => :any,
      :methods => [:post],
      :max_age => 0

    resource '*',
      :headers => :any,
      :methods => [:get, :post, :delete, :put, :patch, :options, :head],
      :max_age => 0
  end
end

# For production, use the URL of your production frontend app.
Rails.application.config.hosts << "https://lorenzosimonassi.gitlab.io/"