module Ragios
  module Events
    class Subscriber < ZMQ::Subscriber

      def initialize
        @worker_pool = Worker.pool(size: 20)

        handler = lambda do |message|
          @worker_pool.async.perform(message)
        end

        super(
          link: Ragios::SERVERS[:events_subscriber],
          topic: "monitor",
          action: :bind_link,
          handler: handler
        )
      end
    end
  end
end
