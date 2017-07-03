module Ragios
  class NotificationPublisher < Ragios::ZMQ

    def initialize
      @link = "tcp://127.0.0.1:5588"
      @socket = zmq_publisher
      connect_link
    end
  end
end
