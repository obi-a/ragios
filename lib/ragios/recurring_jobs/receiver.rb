#receive jobs from clients
module Ragios
  module RecurringJobs
    class Receiver < ZMQ::Receiver

      attr_reader :receiver, :link, :scheduler

      def initialize(skip_scheduler_creation = false)
        unless skip_scheduler_creation
          @scheduler = Ragios::RecurringJobs::Scheduler.new
          async.start_active_jobs
        end
        handler = lambda do |message|
          @scheduler.perform(message)
        end
        super(
          link: Ragios::SERVERS[:recurring_jobs_receiver],
          socket: :zmq_dealer,
          action: :bind_link,
          handler: handler
        )
      end

    private

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

      def model
        @model ||= Ragios::Database::Model.new
      end
    end
  end
end
