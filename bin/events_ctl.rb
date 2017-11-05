#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

options = {
  log_output: true,
  dir_mode: :normal,
  dir: 'tmp/pids',
  keep_pid_files: false,
  ontop: true
}

Daemons.run_proc('events', options) do
  require "#{ragios_dir}/lib/ragios"

  Ragios::Logging.setup(program_name: "Events Service")

  Ragios::Logging.logger.info("starting out")

  receiver = Ragios::Events::Receiver.new
  trap("INT") {puts "Shutting down."; exit}

  receiver.run
end
