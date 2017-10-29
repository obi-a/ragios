module Ragios
  module Events
    class Receiver < ZMQ::Receiver
      attr_reader :worker_pool

      def initialize
        @worker_pool = Worker.pool(size: 20)

        handler = lambda do |message|
          @worker_pool.async.perform(message.first)
        end

        super(
          link: Ragios::SERVERS[:events_receiver],
          socket: :zmq_dealer,
          action: :bind_link,
          handler: handler
        )
      end
    end
  end
end
