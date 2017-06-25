module Ragios
  class ZMQ
    include Celluloid::ZMQ
    attr_reader :socket, :link, :handler

    def run
      loop { async.handle_message(@socket.read_multipart) }
    end

    def handle_message(message)
      @handler.call(message)
    end

    def push(monitor_id)
      write(monitor_id)
      puts "#{Time.now} push work for monitor_id: #{monitor_id} to worker"
    end

    def log_event(options)
      publish(options[:event_type], options[:monitor_id], options)
      puts "#{Time.now} Publish event: #{options}"
    end

    def terminate
      @socket.close
      super
    end

    def close
      @socket.close
      terminate
    end

    protected

    def write(message)
      @socket << message
      nil
    end

    def publish(topic, monitor_id, event)
      @socket.write(topic, monitor_id, JSON.generate(event))
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
