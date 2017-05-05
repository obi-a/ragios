module Ragios
  class MonitorsManager
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

      #add_to_scheduler(this_generic_monitor)
      #add monitor's job to scheduler
      model.save(monitor_id, monitor_options)
      #log_event(
      #  monitor_id: this_generic_monitor.id,
      #  event: {"monitor status" => "created"},
      #  state: "create",
      #  time: event_time,
      #  type: "event",
      #  event_type: "monitor.create"
      # )
      #log_monitor_start(this_generic_monitor.id, this_generic_monitor.options)
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
        puts "scheduler.unschedule(monitor_id)"
        #log_event(
        #  monitor_id: monitor_id,
        #  event: {"monitor status" => "stopped"},
        #  state: "stopped",
        #  time: time,
        #  type: "event",
        #  event_type: "monitor.stop"
        #)
        puts "log event monitor.stop"
        !!model.update(monitor_id, status_: "stopped")
      end
    end

    Contract Monitor_id => Bool
    def delete(monitor_id)
      try_monitor(monitor_id) do
        #monitor = model.find(monitor_id)
        puts "scheduler.unschedule(monitor_id)"
        !!model.delete(monitor_id)
        #log_event(
        #  monitor_id: monitor_id,
        #  event: {"monitor status" => "deleted"},
        #  state: "deleted",
        #  time: time,
        #  type: "event",
        #  event_type: "monitor.delete"
        #)
        #if found exits delete it
        puts "log event monitor.delete"
        true
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
        puts "reschedule job" if options.keys.include?(:every)
        #monitor = model.find(monitor_id)
        #log_event(
        #  monitor_id: monitor_id,
        #  state: "updated",
        #  event: {"monitor status" => "updated"},
        #  time: time,
        #  monitor: monitor,
        #  update: options,
        #  type: "event",
        #  event_type: "monitor.update"
        #)
        #if is_active?(monitor)
        #  scheduler.unschedule(monitor_id)
        #  updated_generic_monitor = update_previous_state(monitor)
        #  add_to_scheduler(updated_generic_monitor)
        #end
        puts "log event monitor.update"
        puts "add_to_scheduler(updated_generic_monitor)"
        true
      end
    end

    Contract Monitor_id => Bool
    def start(monitor_id)
      try_monitor(monitor_id) do
        #monitor = get_valid_monitor(monitor_id)
        #return true if is_active?(monitor)
        #updated_generic_monitor = update_previous_state(monitor)
        puts "add_to_scheduler(updated_generic_monitor)"
        puts "log_monitor_start(monitor_id, monitor)"
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
          #updated_generic_monitor = update_previous_state(monitor) rescue next
          puts "add_to_scheduler(updated_generic_monitor)"
        end
      end
    end

    private

    def model
      @model ||= Ragios::Database::Model.new(Ragios::CouchdbAdmin.get_database)
    end

    def get_valid_monitor(monitor_id)
      monitor = model.find(monitor_id)
      if monitor[:type] != "monitor"
        raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}"
      else
        return monitor
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