require "celluloid/zmq/current"
require "json"

Celluloid::ZMQ.init

module Ragios
  class WorkReceiver
    include Celluloid::ZMQ
    attr_reader :socket

    def initialize
      @link = "tcp://127.0.0.1:5688"
      @socket = Socket::Dealer.new
      begin
        @socket.bind(@link)
      rescue IOError
        @socket.close
        raise
      end
    end

    def run
      loop { async.handle_message(@socket.read_multipart) }
    end

    def handle_message(message)
      puts "got message: #{message}"

    end

    def terminate
      @socket.close
      super
    end
  end
end
