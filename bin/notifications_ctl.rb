#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc('notifications', log_output: true) do

  require "#{ragios_dir}/lib/ragios"

  Ragios::Logging.setup(program_name: "Notifications Service")

  Ragios::Logging.logger.info("starting out")

  receiver = Ragios::Notifications::Receiver.new
  trap("INT") { puts "Shutting down."; exit}
  receiver.run
end
