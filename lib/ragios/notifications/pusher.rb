module Ragios
  module Notifications
    class Pusher < ZMQ::Pusher

      def initialize
        super(
          link: Ragios::SERVERS[:notifications_receiver],
          socket: :zmq_dealer,
          action: :connect_link
        )
      end
    end
  end
end
