module Ragios
  module RecurringJobs
    class Pusher
      include Celluloid::ZMQ

      def initialize
        @link = "tcp://127.0.0.1:5555"
        @socket = zmq_dealer
        @socket.linger = 100
        connect_link
      end

      def write(message)
        @socket << message
        nil
      end

      def push(monitor_id)
        write(monitor_id)
      end

      def terminate
        @socket.close
        super
      end

    private


      def zmq_dealer
        Socket::Dealer.new
      end


      def connect_link
        begin
          @socket.connect(@link)
        rescue IOError
          @socket.close
          raise
        end
      end
    end
  end
end
