#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc('events', log_output: true) do
  require "#{ragios_dir}/lib/ragios"

  Ragios::Logging.setup(program_name: "Events Service")

  Ragios::Logging.logger.info("starting out")

  receiver = Ragios::Events::Receiver.new
  trap("INT") {puts "Shutting down."; exit}

  receiver.run
end
