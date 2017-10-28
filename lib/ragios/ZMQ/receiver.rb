module Ragios
  module ZMQ
    class Receiver < Base
      attr_reader :handler

      def initialize(options)
        @handler = options[:handler]
        super(options)
      end

      def run
        loop { async.handle_message(receive) }
      end

      def receive
        @socket.read_multipart
      end

      def handle_message(message)
        @handler.call(message)
        Ragios.logger.info "#{self.class.name} received message: #{message}"
      end
    end
  end
end
