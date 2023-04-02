require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

s.every '200m' do
    #Rails.logger.info "hello, it's #{Time.now}"
    #Rails.logger.flush
    puts "logando #{Time.now}"
  end

  s.every '300m' do
    puts 'atualizando DB'
  end
  