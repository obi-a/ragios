#this is the same code as work_manager
# DRY both managers as WorkManager Base class
module Ragios
  class NotificationManager
    include Celluloid::ZMQ

    attr_reader :topic

    def initialize(topic)
      @link = "tcp://127.0.0.1:5555"
      @socket = zmq_subscriber
      @topic = "monitor"
      @socket.subscribe(@topic)
      bind_link
      @worker_pool = Ragios::NotificationJob.pool(size: 20)
    end

    def run
      loop do
        puts "Waiting for response..."
        #async.handle_message(@subscriber.read_multipart)
        #Handler.new.async.handle_message(@subscriber.read_multipart)
        @worker_pool.async.perform(@subscriber.read_multipart)
      end
    end

    def terminate
      @socket.close
      super
    end

  private

    def zmq_subscriber
      Socket::Sub.new
    end

    def bind_link
      @socket.bind(@link)
    rescue IOError
      @socket.close
      raise
    end
  end
end
