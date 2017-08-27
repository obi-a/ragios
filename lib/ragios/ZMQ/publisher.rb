module Ragios
  module ZMQ
    class Publisher < Base
      attr_reader :topic

      def initialize(options)
        super(options.merge(socket: :zmq_publisher))
      end

      def log_event(options)
        publish(options[:event_type], options[:monitor_id], options)
        Ragios.log_event(self, "published", options)
      end

      def log_event!(options)
        log_event(options)
        close
      end

    protected

      def publish(topic, monitor_id, event)
        @socket.write(topic, monitor_id, JSON.generate(event))
      end
    end
  end
end
