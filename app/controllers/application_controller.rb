class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def render_resource(resource)
    if resource.errors.empty?
      puts 'estou aqui no application controller'
      render json: resource
    else
      validation_error(resource)
    end
  end

  def validation_error(resource)
    puts 'estou aqui no application controller no validation_error'
    render json: {
      errors: [
        {
          status: '400',
          title: 'Bad Request',
          detail: resource.errors,
          code: '100'
        }
      ]
    }, status: :bad_request
  end
end
