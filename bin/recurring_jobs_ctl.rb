#!/usr/bin/env ruby
require 'daemons'

ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
config = ragios_dir + '/config'
require config
receiver = Ragios::RecurringJobs::Receiver.new

puts "starting out"
Daemons.run_proc('recurring_jobs', log_output: true) do

  #trap("INT") { puts "Shutting down."; pull.terminate; exit}
  trap 'TERM', lambda { puts "Shutting down."; receiver.terminate;}
  receiver.run
end
