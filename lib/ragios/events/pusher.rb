module Ragios
  module Events
    class Pusher < ZMQ::Pusher

      def initialize
        super(
          link: Ragios::SERVERS[:events_receiver],
          socket: :zmq_dealer,
          action: :connect_link
        )
      end

      def log_event(options)
        raise ArgumentError.new("Expected Argument must be a Hash") unless options.is_a?(Hash)
        push(JSON.generate(options))
        Ragios.log_event(self, "pushed", options)
      end

      def log_event!(options)
        log_event(options)
        close
      end
    end
  end
end
