#receive jobs from clients
module Ragios
  module RecurringJobs
    class Receiver < ZMQ::Receiver

      attr_reader :receiver, :link, :scheduler

      def initialize
        @link = "tcp://127.0.0.1:5677"
        @socket = zmq_dealer
        bind_link
        @scheduler = Ragios::RecurringJobs::Scheduler.new
        async.start_active_jobs
        @handler = lambda do |message|
          puts "got message: #{message}"
          @scheduler.perform(message)
        end
      end

      def start_active_jobs
        monitors = model.active_monitors
        unless monitors.empty?
          monitors.each do |monitor|
            @scheduler.schedule_and_run_later(
              monitor_id: monitor[:_id],
              interval: monitor[:every]
            )
          end
        end
      end

    private
      def model
        @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
      end
    end
  end
end
