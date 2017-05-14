require 'pathname'

dir = Pathname(__FILE__).dirname.expand_path

require 'celluloid/debug'
require "celluloid/zmq/current"
require "json"

Celluloid::ZMQ.init

#POOL_SIZE = 100

require dir + 'jobs_service/receiver'
require dir + 'jobs_service/ragios_job'

puts "Starting up"

#supervisor = Ragios::Job::Receiver.supervise as: :jobs_receiver
#supervisor[:jobs_receiver].run

receiver = Ragios::Job::Receiver.new
receiver.run

trap("INT") { puts "Shutting down."; receiver.terminate; exit}

loop do
end
