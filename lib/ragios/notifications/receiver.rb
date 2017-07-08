module Ragios
  module Notifications
    class Receiver  < Ragios::ZMQ

      def initialize
        @link = "tcp://127.0.0.1:5588"
        @socket = zmq_dealer
        bind_link
        @worker_pool = NotificationWorker.pool(size: 20)

        @handler = lambda do |message|
          puts "got message: #{message}"
          @worker_pool.async.perform(message.first)
        end
      end
    end
  end
end
