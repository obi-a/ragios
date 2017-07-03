module Ragios
  module Notifications
    class Subscriber < Ragios::ZMQ

      attr_reader :topic

      def initialize
        @link = "tcp://127.0.0.1:5588"
        @socket = zmq_subscriber
        @topic = "monitor"
        @socket.subscribe(@topic)
        bind_link
        @worker_pool = NotificationWorker.pool(size: 20)
      end

      def run
        loop do
          puts "Waiting for response..."
          @worker_pool.async.perform(@socket.read_multipart.last)
        end
      end
    end
  end
end
