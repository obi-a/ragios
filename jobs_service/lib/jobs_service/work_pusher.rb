module Ragios
  class WorkPusher
    include Celluloid::ZMQ

    def initialize
      @link = "tcp://127.0.0.1:5679"
      @socket = zmq_dealer
      bind_link
      @scheduler = Ragios::JobScheduler.new
    end

    def write(message)
      @socket << message
      nil
    end

    def push(options)

    end

    def terminate
      @socket.close
      super
    end

  private

    def zmq_dealer
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
