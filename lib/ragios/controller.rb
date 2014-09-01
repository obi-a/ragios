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

    Contract Monitor_id => Bool
    def self.stop(monitor_id)
      try_monitor(monitor_id) do
        scheduler.unschedule(monitor_id)
        !!model.update(monitor_id, status_: "stopped")
      end
    end

    Contract Monitor_id => Bool
    def self.delete(monitor_id)
      try_monitor(monitor_id) do
        monitor = model.find(monitor_id)
        scheduler.unschedule(monitor_id) if is_active?(monitor)
        !!model.delete(monitor_id)
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
        monitor = model.find(monitor_id)
        if include_current_state
          current_state = get_current_state(monitor_id)
          monitor[:current_state_] =  {
            state: current_state[:state],
            test_result: current_state[:test_result],
            time_of_test: current_state[:time_of_test],
            timestamp_of_test: current_state[:timestamp_of_test]
          }
        end
        return monitor
      end
    end

    Contract None => ArrayOf[Monitor]
    def self.get_all
      model.all_monitors
    end

    Contract Monitor_id => Bool
    def self.restart(monitor_id)
      try_monitor(monitor_id) do
        monitor = model.find(monitor_id)
        return true if is_active?(monitor)
        updated_generic_monitor = update_previous_state(monitor)
        add_to_scheduler(updated_generic_monitor)
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

    Contract Hash => ArrayOf[Monitor]
    def self.where(options)
      model.monitors_where(options)
    end

    #only called when first starting the application
    #to restart all active monitors from database to scheduler
    Contract None => Or[ArrayOf[Monitor], nil]
    def self.restart_all_active
      monitors = model.active_monitors
      unless monitors.empty?
        monitors.each do |monitor|
          updated_generic_monitor = update_previous_state(monitor) rescue next
          add_to_scheduler(updated_generic_monitor)
        end
      end
    end

    Contract Monitor_id => Hash
    def self.get_current_state(monitor_id)
      model.get_monitor_state(monitor_id)
    end

    Contract Hash => Monitor
    def self.add(monitor)
      monitor_with_id = monitor.merge({created_at_: Time.now, status_: 'active', _id: unique_id, type: "monitor"})
      this_generic_monitor = generic_monitor(monitor_with_id)
      add_to_scheduler(this_generic_monitor)
      model.save(this_generic_monitor.id, this_generic_monitor.options)
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

  private
    def self.update_previous_state(monitor)
      monitor_id = monitor[:_id]
      this_generic_monitor = generic_monitor(monitor)
      if get_current_state(monitor_id) && get_current_state(monitor_id)[:state]
        this_generic_monitor.state = get_current_state(monitor_id)[:state].to_sym
      end
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

    def self.save_notification(event, monitor, test_result, notifier)
      model.save(unique_id,
        monitor_id: monitor[:_id],
        monitor: monitor,
        test_result: test_result,
        type: "notification",
        notifier: notifier,
        tag: monitor[:tag],
        created_at: Time.now,
        event: event)
    end

    def self.unique_id
      UUIDTools::UUID.random_create.to_s
    end

    def self.log_results(this_generic_monitor)
      test_result = {
        monitor_id: this_generic_monitor.id,
        state: this_generic_monitor.state,
        test_result: this_generic_monitor.test_result,
        time_of_test: this_generic_monitor.time_of_test,
        timestamp_of_test: this_generic_monitor.timestamp_of_test,
        monitor: this_generic_monitor.options,
        tag: this_generic_monitor.options[:tag],
        type: "test_result",
        created_at: Time.now
      }
      model.save(unique_id, test_result)
    end

    def self.log_error(this_generic_monitor, exception)
      test_result = {
        monitor_id: this_generic_monitor.id,
        state: "error",
        test_result: {error: exception.message},
        time_of_test: Time.now,
        timestamp_of_test: Time.now.to_i,
        monitor: this_generic_monitor.options,
        tag: this_generic_monitor.options[:tag],
        type: "test_result",
        created_at: Time.now
      }
      model.save(unique_id, test_result)

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
