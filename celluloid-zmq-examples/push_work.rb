require "celluloid/zmq/current"

Celluloid::ZMQ.init

class PushWork
  include Celluloid::ZMQ

  def initialize

    @link = "tcp://127.0.0.1:5677"
    @socket = Socket::Push.new
    begin
      @socket.connect(@link)
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

pull = PullDealer.new
pull.run

trap("INT") { puts "Shutting down."; pull.terminate; exit}

puts "Starting up"

loop do
end

