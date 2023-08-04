# populate_tiny_db.rb
class PopulateTinyDb
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed, unique_args: :unique_args
  sidekiq_options retry: false

  def self.unique_args(args)
    # Use the first argument as the unique identifier
    args.first
  end

  def perform
    puts '** SIDEKIQ JOB STARTED ** '
    tiny = ApiTiny::TinyApiService.new()

    begin
      tiny.build_and_update_estoque_db
      tiny.atualiza_quantidade_por_id
    rescue RestClient::ExceptionWithResponse => e
      puts "Error fetching data from Tiny API: #{e.message}"
    end
  end

  private

  def calculate_retry_interval(exception)
    # Implement your logic here to calculate the retry interval, e.g., exponential backoff, etc.
    # For example, you can use the exception class or status code to determine the type of error.
    # In this example, we use a fixed retry interval of 5 seconds.
    5
  end
end
