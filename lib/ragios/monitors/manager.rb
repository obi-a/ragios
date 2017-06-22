module Ragios
  module Monitors
    class Manager
      #see contracts: https://github.com/egonSchiele/contracts.ruby
      include Contracts
      #types
      Monitor = Hash
      Monitor_id = String


      attr_reader :model

      def initialize(options = {})
      end

      Contract Hash => Monitor
      def add(options)
        event_time = time
        monitor_id = unique_id
        monitor_options = options.merge({created_at_: event_time, status_: 'active', type: "monitor"})

        model.save(monitor_id, monitor_options)
        schedule(monitor_id, monitor_options[:every], first_run = true)
        publisher.log_event(
          monitor_id: monitor_id,
          event: {"monitor status" => "created"},
          state: "create",
          time: event_time,
          type: "event",
          event_type: "monitor.create"
        )
        log_monitor_start(monitor_id, monitor_options)
        return monitor_options.merge(_id: monitor_id)
      end

      Contract Monitor_id, Bool => Monitor
      def get(monitor_id, include_current_state = false)
        try_monitor(monitor_id) do
          monitor = get_valid_monitor(monitor_id)
          if include_current_state
            current_state = get_current_state(monitor_id)
            monitor[:current_state_] =  {
              state: current_state[:state],
              test_result: current_state[:event],
              time_of_test: current_state[:time]
            }
          end
          return monitor
        end
      end

      Contract Monitor_id => Hash
      def self.get_current_state(monitor_id)
        model.get_monitor_state(monitor_id)
      end


      Contract Monitor_id => Bool
      def stop(monitor_id)
        try_monitor(monitor_id) do
          unschedule(monitor_id)
          !!model.update(monitor_id, status_: "stopped")
          !!publisher.log_event(
            monitor_id: monitor_id,
            event: {"monitor status" => "stopped"},
            state: "stopped",
            time: time,
            type: "event",
            event_type: "monitor.stop"
          )
        end
      end

      Contract Monitor_id => Bool
      def delete(monitor_id)
        try_monitor(monitor_id) do
          !!model.delete(monitor_id)
          unschedule(monitor_id)
          !!publisher.log_event(
            monitor_id: monitor_id,
            event: {"monitor status" => "deleted"},
            state: "deleted",
            time: time,
            type: "event",
            event_type: "monitor.delete"
          )
        end
      end


      Contract Monitor_id, Hash => Bool
      def update(monitor_id, options)
        try_monitor(monitor_id) do
          message = "Cannot edit system settings"
          if options.keys.any? { |key| [:type, :status_, :created_at_, :creation_timestamp_, :current_state_].include?(key) }
            raise Ragios::CannotEditSystemSettings.new(error: message), message
          end
          model.update(monitor_id, options)
          reschedule(monitor_id, options[:every]) if options.keys.include?(:every)
          publisher.log_event(
            monitor_id: monitor_id,
            state: "updated",
            event: {"monitor status" => "updated"},
            time: time,
            update: options,
            type: "event",
            event_type: "monitor.update"
          )
          true
        end
      end

      Contract Monitor_id => Bool
      def start(monitor_id)
        try_monitor(monitor_id) do
          monitor = get_valid_monitor(monitor_id)
          #return true if is_active?(monitor)
          #updated_generic_monitor = update_previous_state(monitor)
          #puts "add_to_scheduler(updated_generic_monitor)"
          reschedule(monitor[:_id], monitor[:every])
          log_monitor_start(monitor_id, monitor)
          !!model.update(monitor_id, status_: "active")
        end
      end

      Contract Monitor_id => Bool
      def test_now(monitor_id)
        try_monitor(monitor_id) do
          #monitor = model.find(monitor_id)
          #!!perform(generic_monitor(monitor))
          puts "ask worker to perform job"
          true
        end
      end

      # only called when first starting the application
      # to start all active monitors from database to scheduler
      # may later have a rake task do this
      Contract None => Or[ArrayOf[Monitor], nil]
      def start_all_active
        monitors = model.active_monitors
        unless monitors.empty?
          monitors.each do |monitor|
            schedule(monitor[:_id], monitor[:every])
          end
        end
      end

      def send_stderr(exception)
        $stderr.puts '-' * 80
        $stderr.puts exception.message
        $stderr.puts exception.backtrace.join("\n")
        $stderr.puts '-' * 80
      end

      #queries
      Contract Any => ArrayOf[Monitor]
      def get_all(options = {})
        model.all_monitors(options)
      end

      Contract Monitor_id, String, Hash => ArrayOf[Hash]
      def get_events_by_state(monitor_id, state, options)
        model.get_monitor_events_by_state(monitor_id, state, options)
      end

      Contract Monitor_id, String, Hash => ArrayOf[Hash]
      def get_events_by_type(monitor_id, event_type, options)
        model.get_monitor_events_by_type(monitor_id, event_type, options)
      end

      Contract Monitor_id, Hash => ArrayOf[Hash]
      def get_events(monitor_id, options)
        model.get_monitor_events(monitor_id, options)
      end

      Contract Hash => ArrayOf[Monitor]
      def where(options)
        model.monitors_where(options)
      end

      Contract Monitor_id => Hash
      def get_current_state(monitor_id)
        model.get_monitor_state(monitor_id)
      end

      #check if rufu-scheduler can be rescheduled without being manually stopped & rescheduled
      def reschedule(monitor_id, interval)
        unschedule(monitor_id)
        schedule(monitor_id, interval )
      end

      def schedule(monitor_id, interval, first_run = false)
        add_to_scheduler({
          monitor_id: monitor_id,
          interval: interval,
          first_run: first_run
        })
      end

      def unschedule(monitor_id)
        add_to_scheduler({
          monitor_id: monitor_id,
          unschedule: true
        })
      end

      def add_to_scheduler(options)
        pusher = Ragios::RecurringJobs::Pusher.new
        pusher.push(JSON.generate(options))
        pusher.terminate
      end

    private

      def log_monitor_start(monitor_id, monitor)
        publisher.log_event(
          monitor_id: monitor_id,
          event: {"monitor status" => "started"},
          state: "started",
          time: time,
          monitor: monitor,
          type: "event",
          event_type: "monitor.start"
        )
      end

      def model
        @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
      end

      def publisher
        Ragios::EventPublisher.new
      end

      def get_valid_monitor(monitor_id)
        monitor = model.find(monitor_id)
        if monitor[:type] != "monitor"
          raise Ragios::MonitorNotFound RunTimeError.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}"
        else
          return monitor
        end
      end

      def self.handle_error(monitor_id, e)
        if e.response[:error] == "not_found"
          raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}"
        else
          raise e
        end
      end

      def try_monitor(monitor_id)
        yield
      rescue Leanback::CouchdbException => e
        handle_error(monitor_id, e)
      end

      def time
        Time.now.utc
      end

      def unique_id
        SecureRandom.uuid
      end
    end
  end
end