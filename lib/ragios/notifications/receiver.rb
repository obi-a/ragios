module Ragios
  module Notifications
    class Receiver < ZMQ::Receiver

      def initialize
        @worker_pool = NotificationWorker.pool(size: 20)

        handler = lambda do |message|
          @worker_pool.async.perform(message.first)
        end
        super(
          link: Ragios::SERVERS[:notifications_receiver],
          socket: :zmq_dealer,
          action: :bind_link,
          handler: handler
        )
      end
    end
  end
end
