module Ragios
  module Monitors
    module Workers
      class Receiver < ZMQ::Receiver

        def initialize
          @worker_pool = Worker.pool(size: 20)

          handler = lambda do |message|
            @worker_pool.async.perform(message.first)
          end
          super(
            link: Ragios::SERVERS[:workers_pusher],
            socket: :zmq_dealer,
            action: :connect_link,
            handler: handler
          )
        end
      end
    end
  end
end
