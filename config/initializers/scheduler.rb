require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

s.every '1m' do
    Rails.logger.info "hello, it's #{Time.now}"
    Rails.logger.flush
    puts 'logando'
  end