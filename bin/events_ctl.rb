#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc('events', log_output: true) do
  require "#{ragios_dir}/lib/ragios"

  puts "starting out"

  receiver = Ragios::Events::Subscriber.new
  trap("INT") {puts "Shutting down."; exit}

  receiver.run
end
