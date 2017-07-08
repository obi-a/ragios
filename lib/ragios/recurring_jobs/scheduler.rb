module Ragios
  module RecurringJobs
    class Scheduler
      attr_reader :scheduler, :work_pusher, :publisher

      def initialize
        @work_pusher = Ragios::Monitors::Workers::Pusher.new
        @scheduler = Rufus::Scheduler.new
        @publisher = Ragios::Events::Publisher.pool(size: 20)
      end

      def perform(options_array)
        options = JSON.parse(options_array.first, symbolize_names: true)
        if options[:first_run]
          run_now_and_schedule(options)
        elsif options[:unschedule]
          unschedule(options[:monitor_id])
        else
          schedule_and_run_later(options)
        end
      end

      def run_now_and_schedule(options)
        @scheduler.interval options[:interval],  :tags => options[:monitor_id] do
          trigger_work(options)
        end
      end

      def schedule_and_run_later(options)
        @scheduler.every options[:interval],  :tags => options[:monitor_id] do
          trigger_work(options)
        end
      end

      def trigger_work(options)
        @work_pusher.async.push(options[:monitor_id])
        @publisher.async.log_event(
          monitor_id: options[:monitor_id],
          event: {"monitor status" => "triggered"},
          state: "triggered",
          time: Time.now.utc,
          type: "event",
          event_type: "monitor.triggered"
        )
      end

      def unschedule(monitor_id)
        jobs = find(monitor_id)
        jobs.each do |job|
          job.unschedule
        end
      end

      def find(monitor_id)
        @scheduler.jobs(tag: monitor_id)
      end

      def terminate
        @work_pusher.terminate
        @socket.close
        super
      end
    end
  end
end
