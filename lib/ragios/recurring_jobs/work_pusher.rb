module Ragios
  class WorkPusher < Ragios::ZMQ

    def initialize
      @link = "tcp://127.0.0.1:5679"
      @socket = zmq_dealer
      bind_link
    end
  end
end
