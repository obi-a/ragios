#receive jobs from clients
module Ragios
  module RecurringJobs
    class Receiver < Ragios::ZMQ
      finalizer :close

      attr_reader :receiver, :link, :scheduler

      def initialize
        @link = "tcp://127.0.0.1:5677"
        @socket = zmq_dealer
        bind_link
        @scheduler = Ragios::RecurringJobs::Scheduler.new
        @handler = lambda do |message|
          puts "got message: #{message}"
          @scheduler.perform(message)
        end
      end
    end
  end
end
