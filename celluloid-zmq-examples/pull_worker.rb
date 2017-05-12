require "celluloid/zmq/current"

Celluloid::ZMQ.init

class PullWorker
  include Celluloid::ZMQ

  def initialize
    @link = "tcp://127.0.0.1:5677"
    @socket = Socket::Pull.new
    @socket.linger = 100
    begin
      @socket.bind(@link)
    rescue IOError
      @socket.close
      raise
    end
  end

  def run
    loop { async.handle_message @socket.read_multipart }
  end

  def handle_message(message)
    puts "got message: #{message}"
  end

  def terminate
    @socket.close
    super
  end
end

pull = PullWorker.new
pull.run

trap("INT") { puts "Shutting down."; pull.terminate; exit}

puts "Starting up"

loop do
end