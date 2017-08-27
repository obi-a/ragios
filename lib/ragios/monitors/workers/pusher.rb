module Ragios
  module Monitors
    module Workers
      class Pusher < ZMQ::Pusher

        def initialize
          super(
            link: Ragios::SERVERS[:workers_pusher],
            socket: :zmq_dealer,
            action: :bind_link
          )
        end
      end
    end
  end
end
