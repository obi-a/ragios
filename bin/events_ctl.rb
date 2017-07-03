#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc('events', log_output: true) do

  config = ragios_dir + '/config'
  require config

  puts "starting out"

  receiver = Ragios::Events::Subscriber.new
  #trap("INT") { puts "Shutting down."; pull.terminate; exit}
  trap 'TERM', lambda { puts "Shutting down."; receiver.terminate;}
  receiver.run
end
