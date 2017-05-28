require "celluloid/zmq/current"
require "json"

Celluloid::ZMQ.init

module Ragios
  class WorkManager
    include Celluloid::ZMQ
    attr_reader :socket

    def initialize
      @link = "tcp://127.0.0.1:5688"
      @socket = omq_dealer
      bind_link
      #set worker pool size in the env
      @worker_pool = Ragios::Worker.pool(size: 20)
    end

    def run
      loop { handle_message(@socket.read_multipart) }
    end

    def handle_message(message)
      @worker_pool.async.perform(message)
      #use proper logging to stdout
      puts "got message: #{message}"
    end

    def terminate
      @socket.close
      super
    end

  private

    def omq_dealer
      Socket::Dealer.new
    end

    def bind_link
      @socket.bind(@link)
    rescue IOError
      @socket.close
      raise
    end
  end
end
