#Controller for monitors
module Ragios
  class Controller
    #see contracts: https://github.com/egonSchiele/contracts.ruby
    include Contracts
    #types
    Monitor = Hash
    Monitor_id = String

    def self.scheduler
      @scheduler ||= Ragios::Scheduler.new(self)
    end

    def self.model
      @model ||= Ragios::Database::Model.new(Ragios::CouchdbAdmin.get_database)
    end

    def self.reset
      @model = nil
      @scheduler = nil
    end

    Contract Monitor_id => Bool
    def self.stop(monitor_id)
      try_monitor(monitor_id) do
        scheduler.unschedule(monitor_id)
        log_event(
          monitor_id: monitor_id,
          event: {"monitor status" => "stopped"},
          state: "stopped",
          time: time,
          type: "event",
          event_type: "monitor.stop"
        )
        !!model.update(monitor_id, status_: "stopped")
      end
    end

    Contract Monitor_id => Bool
    def self.delete(monitor_id)
      try_monitor(monitor_id) do
        monitor = model.find(monitor_id)
        scheduler.unschedule(monitor_id) if is_active?(monitor)
        !!model.delete(monitor_id)
        log_event(
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
    def self.update(monitor_id, options)
      try_monitor(monitor_id) do
        message = "Cannot edit system settings"
        if options.keys.any? { |key| [:type, :status_, :created_at_, :creation_timestamp_, :current_state_].include?(key) }
          raise Ragios::CannotEditSystemSettings.new(error: message), message
        end
        model.update(monitor_id, options)
        monitor = model.find(monitor_id)
        log_event(
          monitor_id: monitor_id,
          state: "updated",
          event: {"monitor status" => "updated"},
          time: time,
          monitor: monitor,
          update: options,
          type: "event",
          event_type: "monitor.update"
        )
        if is_active?(monitor)
          scheduler.unschedule(monitor_id)
          updated_generic_monitor = update_previous_state(monitor)
          add_to_scheduler(updated_generic_monitor)
        end
        true
      end
    end

    Contract Monitor_id, Bool => Monitor
    def self.get(monitor_id, include_current_state = false)
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

    Contract Monitor_id => Bool
    def self.start(monitor_id)
      try_monitor(monitor_id) do
        monitor = get_valid_monitor(monitor_id)
        return true if is_active?(monitor)
        updated_generic_monitor = update_previous_state(monitor)
        add_to_scheduler(updated_generic_monitor)
        log_monitor_start(monitor_id, monitor)
        !!model.update(monitor_id, status_: "active")
      end
    end

    Contract Monitor_id => Bool
    def self.test_now(monitor_id)
      try_monitor(monitor_id) do
        monitor = model.find(monitor_id)
        !!perform(generic_monitor(monitor))
      end
    end

    #only called when first starting the application
    #to start all active monitors from database to scheduler
    Contract None => Or[ArrayOf[Monitor], nil]
    def self.start_all_active
      monitors = model.active_monitors
      unless monitors.empty?
        monitors.each do |monitor|
          updated_generic_monitor = update_previous_state(monitor) rescue next
          add_to_scheduler(updated_generic_monitor)
        end
      end
    end

    Contract Hash => Monitor
    def self.add(monitor)
      event_time = time
      monitor_with_id = monitor.merge({created_at_: event_time, status_: 'active', _id: unique_id, type: "monitor"})
      this_generic_monitor = generic_monitor(monitor_with_id)
      add_to_scheduler(this_generic_monitor)
      model.save(this_generic_monitor.id, this_generic_monitor.options)
      log_event(
        monitor_id: this_generic_monitor.id,
        event: {"monitor status" => "created"},
        state: "create",
        time: event_time,
        type: "event",
        event_type: "monitor.create"
      )
      log_monitor_start(this_generic_monitor.id, this_generic_monitor.options)
      return this_generic_monitor.options
    end

    def self.perform(this_generic_monitor)
      this_generic_monitor.test_command?
      log_results(this_generic_monitor)
    rescue Leanback::CouchdbException => e
      stop_on_error(this_generic_monitor.id, this_generic_monitor.options)
      raise e
    rescue Exception => e
      stop_on_error(this_generic_monitor.id, this_generic_monitor.options)
      log_error(this_generic_monitor, e)
    end

    def self.failed(monitor, test_result, notifier)
      save_notification("failed", monitor, test_result, notifier)
    end

    def self.resolved(monitor, test_result, notifier)
      save_notification("resolved", monitor, test_result, notifier)
    end

    def self.notifier_failure(notifier, exception, event, monitor, test_result)
      log_event(
        monitor_id: monitor[:_id],
        event: {"notifier error" => exception.message},
        state: event,
        time: time,
        type: "event",
        event_type: "monitor.notification",
        monitor: monitor,
        test_result: test_result,
        notifier: notifier
      )
      send_stderr(exception)
    end

    #queries
    Contract Any => ArrayOf[Monitor]
    def self.get_all(options = {})
      model.all_monitors(options)
    end

    Contract Monitor_id, String, Hash => ArrayOf[Hash]
    def self.get_events_by_state(monitor_id, state, options)
      model.get_monitor_events_by_state(monitor_id, state, options)
    end

    Contract Monitor_id, String, Hash => ArrayOf[Hash]
    def self.get_events_by_type(monitor_id, event_type, options)
      model.get_monitor_events_by_type(monitor_id, event_type, options)
    end

    Contract Monitor_id, Hash => ArrayOf[Hash]
    def self.get_events(monitor_id, options)
      model.get_monitor_events(monitor_id, options)
    end

    Contract Hash => ArrayOf[Monitor]
    def self.where(options)
      model.monitors_where(options)
    end

    Contract Monitor_id => Hash
    def self.get_current_state(monitor_id)
      model.get_monitor_state(monitor_id)
    end

  private
    def self.time
      Time.now.utc
    end
    def self.update_previous_state(monitor)
      monitor_id = monitor[:_id]
      this_generic_monitor = generic_monitor(monitor)
      current_state = get_current_state(monitor_id)
      this_generic_monitor.state = current_state[:state].to_sym if current_state[:state]
      return this_generic_monitor
    end

    def self.try_monitor(monitor_id)
      yield
    rescue Leanback::CouchdbException => e
      handle_error(monitor_id, e)
    end

    def self.handle_error(monitor_id, e)
      if e.response[:error] == "not_found"
        raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}"
      else
        raise e
      end
    end

    def self.get_valid_monitor(monitor_id)
      monitor = model.find(monitor_id)
      if monitor[:type] != "monitor"
        raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}"
      else
        return monitor
      end
    end

    def self.save_notification(event, monitor, test_result, notifier)
      notification = {notified: event, via: notifier}
      log_event(
        monitor_id: monitor[:_id],
        state: event,
        event: notification,
        time: time,
        monitor: monitor,
        type: "event",
        event_type: "monitor.notification",
        test_result: test_result,
        notifier: notifier
      )
    end

    def self.unique_id
      UUIDTools::UUID.random_create.to_s
    end

    def self.create_result(result, state, this_generic_monitor)
      {
        monitor_id: this_generic_monitor.id,
        state: state,
        event: result,
        time: this_generic_monitor.time_of_test,
        monitor: this_generic_monitor.options,
        type: "event",
        event_type: "monitor.test"
      }
    end

    def self.log_event(event)
      model.save(unique_id, event)
    end

    def self.log_monitor_start(monitor_id, monitor)
      log_event(
        monitor_id: monitor_id,
        event: {"monitor status" => "started"},
        state: "started",
        time: time,
        monitor: monitor,
        type: "event",
        event_type: "monitor.start"
      )
    end

    def self.log_results(this_generic_monitor)
      test_result = create_result(this_generic_monitor.test_result, this_generic_monitor.state, this_generic_monitor)
      log_event(test_result)
    end

    def self.log_error(this_generic_monitor, exception)
      test_result = create_result({error: exception.message}, "error", this_generic_monitor)
      log_event(test_result)
      send_stderr(exception)
    end

    def self.send_stderr(exception)
      $stderr.puts '-' * 80
      $stderr.puts exception.message
      $stderr.puts exception.backtrace.join("\n")
      $stderr.puts '-' * 80
    end

    def self.stop_on_error(monitor_id, monitor_options)
      $stderr.puts '-' * 80
      $stderr.puts "Stopping  #{monitor_id} due to error."
      $stderr.puts "Fix monitor and restart: #{monitor_options.inspect}"
      $stderr.puts '-' * 80
      stop(monitor_id)
    end

    def self.generic_monitor(monitor)
      GenericMonitor.new(monitor)
    end

    def self.is_active?(monitor)
      monitor[:status_] == "active"
    end

    def self.add_to_scheduler(generic_monitor)
      args = {
        time_interval: generic_monitor.options[:every],
        tags: generic_monitor.id,
        object: generic_monitor
      }
      scheduler.schedule(args)
    end
  end
end
