module Ragios
  module RecurringJobs
    class Scheduler
      attr_reader :internal_scheduler, :work_pusher, :events_pusher

      ACTIONS = %w(run_now_and_schedule schedule_and_run_later trigger_work reschedule unschedule).freeze

      # interval jobs - trigger immediately and  then triggers every time the set interval has elasped
      # every jobs - don't trigger immediately, it triggers first when the set interval has elasped and keep recurring at that interval
      TYPES = [:every, :interval].freeze

      def initialize(skip_actor_creation = false)
        @internal_scheduler = Rufus::Scheduler.new
        unless skip_actor_creation
          @work_pusher = Ragios::Monitors::Workers::Pusher.new
          @events_pusher = Ragios::Events::Pusher.pool(size: 20)
        end
      end

      def perform(options_array)
        options = JSON.parse(options_array.first, symbolize_names: true)
        send(options[:perform], options) if ACTIONS.include?(options[:perform])
      end

      def run_now_and_schedule(options)
        schedule(:interval, options)
      end

      def schedule_and_run_later(options)
        schedule(:every, options)
      end

      def reschedule(options)
        unschedule(options)
        schedule_and_run_later(options)
      end

      def schedule(scheduler_type, options)
        unless TYPES.include?(scheduler_type)
          raise ArgumentError.new("Unrecognized scheduler_type #{scheduler_type}")
        end

        opts = {
          tags: options[:monitor_id]
        }

        opts[:first] = :now  if scheduler_type == :interval

        job_id = @internal_scheduler.interval options[:interval].to_s, opts do
          trigger_work(options)
        end

        if job_id
          logger.info("#{self.class.name} scheduled #{scheduler_type} job #{job_id} for monitor_id #{options[:monitor_id]} at interval #{options[:interval]}")
        end
      end

      def trigger_work(options)
        @work_pusher&.async&.push(options[:monitor_id])
        @events_pusher&.async&.log_event(
          monitor_id: options[:monitor_id],
          event: {"monitor status" => "triggered"},
          state: "triggered",
          time: Time.now.utc,
          type: "event",
          event_type: "monitor.triggered"
        )
      end

      def unschedule(options)
        jobs = find(options[:monitor_id])
        jobs.each do |job|
          job.unschedule
          logger.info("#{self.class.name} unscheduled job: #{job.id} for tags #{job.tags}")
        end
      end

      def find(tag)
        @internal_scheduler.jobs(tag: tag)
      end

      private

      def logger
        ::Ragios::Logging.logger
      end
    end
  end
end
