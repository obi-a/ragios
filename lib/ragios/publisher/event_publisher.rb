module Ragios
  class EventPublisher < Ragios::ZMQ

    def initialize
      @link = "tcp://127.0.0.1:5555"
      @socket = zmq_publisher
      @socket.linger = 100
      connect_link
    end
  end
end
