require 'pathname'

dir = Pathname(__FILE__).dirname.expand_path

require "celluloid/zmq/current"

Celluloid::ZMQ.init

#POOL_SIZE = 100

require dir + 'jobs_service/receiver'

puts "Starting up"

#Ragios::Job::Receiver.supervise as: :jobs_receiver

#receiver  = Celluloid::Actor[:jobs_receiver]

receiver = Ragios::Job::Receiver.new
receiver.run

trap("INT") { puts "Shutting down."; receiver.terminate; exit}

loop do
end
