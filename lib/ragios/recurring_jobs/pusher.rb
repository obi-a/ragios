module Ragios
  module RecurringJobs
    class Pusher < Ragios::ZMQ

      def initialize
        @link = "tcp://127.0.0.1:5677"
        @socket = zmq_dealer
        @socket.linger = 100
        connect_link
      end
    end
  end
end
