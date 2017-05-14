#receive jobs from clients
module Ragios
  module Job
    class Receiver
      include Celluloid::ZMQ

      attr_reader :socket, :link, :supervisor

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
        loop { handle_message(@socket.read_multipart) }
      end

      def handle_message(message)
        puts "got message: #{message}"
        @supervisor = Ragios::RagiosJob.supervise as: :job
        @supervisor[:job].async.init(message)
      end

      def terminate
        @socket.close
        super
      end
    end
  end
end
