module Ragios
  module Events
    class Subscriber < ZMQ::Receiver

      def initialize
        @link = "tcp://127.0.0.1:5555"
        @socket = zmq_subscriber
        @topic = "monitor"
        @socket.subscribe(@topic)
        bind_link
        @worker_pool = Worker.pool(size: 20)
      end

      def run
        loop do
          puts "Waiting for response..."
          #async.handle_message(@subscriber.read_multipart)
          #Handler.new.async.handle_message(@subscriber.read_multipart)
          @worker_pool.async.perform(@socket.read_multipart.last)
        end
      end
    end
  end
end
