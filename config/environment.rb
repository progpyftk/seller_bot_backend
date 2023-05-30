# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
# config/environments/<environment>.rb
Rails.application.configure do
    # Other configuration settings...
  
    config.hosts << "seller-bot-1094006061.us-west-2.elb.amazonaws.com"
  
    # Remaining configuration settings...
  end
  