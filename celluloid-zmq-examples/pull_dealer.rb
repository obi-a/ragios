require "celluloid/zmq/current"

Celluloid::ZMQ.init

class PullDealer
  include Celluloid::ZMQ

  def initialize

    @link = "tcp://127.0.0.1:5677"
    @socket = Socket::Dealer.new
    begin
      @socket.connect(@link)
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

pull = PullDealer.new
pull.async.run

trap("INT") { puts "Shutting down."; pull.terminate; exit}

puts "Starting up"

loop do
end

