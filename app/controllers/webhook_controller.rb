class WebhookController < ApplicationController
    def handle
        # Process the webhook payload here
        puts 'aqui'
        payload = request.body.read
        pp payload

        # Return HTTP 200 status code
        head :ok
    end
end