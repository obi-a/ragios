module Ragios
  module ZMQ
    class Publisher < Base
      attr_reader :topic


      def log_event(options)
        publish(options[:event_type], options[:monitor_id], options)
        puts "#{Time.now} Publish event: #{options}"
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
