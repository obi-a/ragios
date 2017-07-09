#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc("workers#{Time.now.to_i}", log_output: true) do

  config = ragios_dir + '/config'
  require config

  puts "starting out"

  receiver = Ragios::Monitors::Workers::Receiver.new
  trap("INT") { puts "Shutting down."; exit}

  receiver.run
end
