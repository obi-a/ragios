require "celluloid/zmq/current"
require "json"

Celluloid::ZMQ.init

class JobsSender
  include Celluloid::ZMQ

  def initialize
    @link = "tcp://127.0.0.1:5677"
    @socket = Socket::Dealer.new
    @socket.linger = 100
    begin
      @socket.connect(@link)
    rescue IOError
      @socket.close
      raise
    end
  end

  def run
    count = 0
    500.times do
      message = JSON.generate({monitor_id: "monitor_#{count}", interval: "5s"})
      write(message)
      count += 1
    end
  end

  def write(message)
    puts "pushing #{message}"
    @socket << message
    nil
  end

  def terminate
    @socket.close
    super
  end
end

push = JobsSender.new
push.run

trap("INT") { puts "Shutting down."; push.terminate; exit}

puts "Starting up"

loop do
end