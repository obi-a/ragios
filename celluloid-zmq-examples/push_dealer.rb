require "celluloid/zmq/current"

Celluloid::ZMQ.init

class PushDealer
  include Celluloid::ZMQ

  def initialize
    @link = "tcp://127.0.0.1:5677"
    @socket = Socket::Dealer.new
    @socket.linger = 100
    begin
      @socket.bind(@link)
    rescue IOError
      @socket.close
      raise
    end
  end

  def run
    count = 0
    10000.times do
      message = "pushed.#{count}"
      write(message)
      sleep 5
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

push = PushDealer.new
push.run

trap("INT") { puts "Shutting down."; push.terminate; exit}

puts "Starting up"

loop do
end