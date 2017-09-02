module Ragios
  module ZMQ
    class Subscriber < Base
      attr_reader :topic, :handler

      def initialize(options)
        @topic = options.fetch(:topic)
        super(options.merge(socket: :zmq_subscriber))
        @handler = options.fetch(:handler)
        @socket.subscribe(@topic)
      end

      def run
        loop { async.handle_message(receive) }
      end

      def receive
        @socket.read_multipart.last
      end

      def handle_message(event)
        @handler.call(event)
        Ragios.log_event(self, "received", event)
      end
    end
  end
end