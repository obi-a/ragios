module Ragios
  module ZMQ
    class Receiver < Base
      attr_reader :handler
      def run
        loop { async.handle_message(@socket.read_multipart) }
      end

      def handle_message(message)
        @handler.call(message)
      end
    end
  end
end
