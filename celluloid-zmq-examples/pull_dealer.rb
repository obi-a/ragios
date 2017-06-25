require "celluloid/zmq/current"

Celluloid::ZMQ.init

class PullDealer
  include Celluloid::ZMQ

  def initialize

    @link = "tcp://127.0.0.1:5679"
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
    puts "#{Time.now} got message: #{message}"
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

