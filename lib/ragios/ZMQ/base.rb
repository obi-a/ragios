module Ragios
  module ZMQ
    class Base
      include Celluloid::ZMQ
      finalizer :clean_up
      attr_reader :socket, :link

      def terminate
        @socket.close
        super
      end

      def close
        @socket.close
        terminate
      end

    protected

      def clean_up
        @socket.close
      end

      def zmq_dealer
        Socket::Dealer.new
      end

      def zmq_publisher
        Socket::Pub.new
      end

      def zmq_subscriber
        Socket::Sub.new
      end

      def connect_link
        @socket.connect(@link)
      rescue IOError
        @socket.close
        raise
      end

      def bind_link
        @socket.bind(@link)
      rescue IOError
        @socket.close
        raise
      end
    end
  end
end
