module Ragios
  module Monitors
    module Workers
      class Pusher < Ragios::ZMQ

        def initialize
          @link = "tcp://127.0.0.1:5679"
          @socket = zmq_dealer
          bind_link
        end
      end
    end
  end
end
