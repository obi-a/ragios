module Ragios
  module RecurringJobs
    class Pusher < ZMQ::Pusher

      def initialize
        super(
          link: Ragios::SERVERS[:recurring_jobs_receiver],
          socket: :zmq_dealer,
          action: :connect_link
        )
      end
    end
  end
end
