module Ragios
  module Monitors
    module Workers
      class Receiver < ZMQ::Receiver

        def initialize
          @link = "tcp://127.0.0.1:5679"
          @socket = zmq_dealer
          connect_link
          #set worker pool size in the env
          @worker_pool = Worker.pool(size: 20)

          @handler = lambda do |message|
            puts "got message: #{message}"
            @worker_pool.async.perform(message.first)
          end
        end
      end
    end
  end
end
