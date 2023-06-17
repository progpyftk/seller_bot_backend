class WebhookController < ApplicationController
    def handle
        puts '--- recebendo post do ML ----'
        # Process the webhook payload here
        payload = request.body.read
        puts '--- recebendo post do ML ----'
        puts '--- entrando no handle de webhooks ----'
        HardJob.perform_async(payload)
        # Return HTTP 200 status code - quem irá 
        head :ok
    end
end