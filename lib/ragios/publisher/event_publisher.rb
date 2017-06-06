module Ragios
  class EventPublisher
    include Celluloid::ZMQ

    def initialize
      @link = "tcp://127.0.0.1:5555"
      @socket = Socket::Pub.new
      @socket.linger = 100
      begin
        @socket.connect(@link)
      rescue IOError
        @socket.close
        raise
      end
    end

    def log_event!(options)
      publish(options[:event_type], options[:monitor_id], options)
      close
    end

    def publish(topic, monitor_id, event)
      @socket.write(topic, monitor_id, JSON.generate(event))
    end

    def close
      @socket.close
      terminate
    end
  end
end
