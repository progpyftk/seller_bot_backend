class WorkerNameJob
  include Sidekiq::Job

  def perform(*args)
    puts '-----comecou-----'
    DbPopulate::UpdateItemsTableService.call
  end
end
