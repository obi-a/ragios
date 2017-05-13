#receive jobs from clients
module Ragios
  module Job
    class Receiver
      include Celluloid::ZMQ

      attr_reader :socket, :link

      def initialize

        @link = "tcp://127.0.0.1:5677"
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
        Ragios::Job.supervise as: :job, args: [message], size: 100
      end

      def terminate
        @socket.close
        super
      end
    end
  end
end
