require "celluloid/zmq/current"

Celluloid::ZMQ.init

class RepServer
  include Celluloid::ZMQ

  def initialize(options = {})
    @link = "tcp://127.0.0.1:5544"
    @socket = Socket::Rep.new
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
    write("ok: true")
  end

  def write(message)
    @socket.write(message)
  end

  def terminate
    @socket.close
    super
  end
end

rep = RepServer.new
rep.run

trap("INT") { puts "Shutting down."; rep.terminate; exit}

puts "Starting up"

loop do
end