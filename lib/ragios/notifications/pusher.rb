module Ragios
  module Notifications
    class Pusher < Ragios::ZMQ

      def initialize
        @link = "tcp://127.0.0.1:5588"
        @socket = zmq_dealer
        connect_link
      end
    end
  end
end
