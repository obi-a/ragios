#!/usr/bin/env ruby
require 'daemons'
ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Daemons.run_proc('recurring_jobs', log_output: true) do

  require "#{ragios_dir}/lib/ragios"

  Ragios::Logger.setup(program_name: "RecurringJobs Service")

  Ragios::Logger.log(:info, "starting out")
  receiver = Ragios::RecurringJobs::Receiver.new

  trap("INT") { puts "Shutting down."; exit}
  receiver.run
end
