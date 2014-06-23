module Ragios
  class Controller
=begin
    def self.scheduler(sch = nil)
      @scheduler ||= sch
    end

    def self.model(m = nil)
      @model ||= m
    end

    def self.logger(lgr = nil)
      @logger ||= lgr
    end
=end
    def self.scheduler
      @scheduler ||= Ragios::Scheduler.new(self)
    end
    def self.model
      @model ||= Ragios::Model::CouchdbMonitorModel
    end
    def self.stop(monitor_id)
      scheduler.unschedule(monitor_id)
      !!model.update(monitor_id, status_: "stopped")
    end
    def self.delete(monitor_id)
      monitor = model.find(monitor_id)
      scheduler.unschedule(monitor_id) if is_active?(monitor)
      model.delete(monitor_id)
    end

    def self.update(monitor_id, options)
      raise "Cannot update system settings" if options.keys.to_set.superset? [:type, :status_, :created_at_, :creation_timestamp_]
      model.update(monitor_id,options)
      monitor = model.find(monitor_id)
      !!restarted =
      if is_active?(monitor)
        scheduler.unschedule(monitor_id)
        add_to_scheduler(generic_monitor(monitor))
      end
    end
=begin
    def self.update(monitor_id, options)
      model.update(monitor_id,options)
      monitor = model.find(monitor_id)
      if is_active?(monitor)
        stop(monitor_id)
        monitor = restart(monitor_id)
      end
      return monitor
    end
=end
    def self.get(monitor_id)
      model.find(monitor_id)
    end
    def self.get_all
      model.all
    end
    def self.restart(monitor_id)
      monitor = model.find(monitor_id)
      return true if is_active?(monitor)
      add_to_scheduler(generic_monitor(monitor))
      !!model.update(monitor_id, status: "active")
    end
=begin
    def self.restart(monitor_id)
      monitor = model.find(monitor_id)
      return monitor if is_active?(monitor)
      generic_monitor = objectify(monitor)
      generic_monitors = add_to_scheduler([generic_monitor])
      generic_monitors.first.options
    end
=end
    def self.test_now(monitor_id)
      monitor = model.find(monitor_id)
      perform(generic_monitor(monitor))
    end

    def self.find_by(options)
      model.where(options)
    end

    def self.restart_all
      monitors = model.active_monitors
      unless monitors.empty?
        monitors.each do |monitor|
          add_to_scheduler(generic_monitor(monitor))
        end
      end
    end

    def self.add(monitor)
      id = UUIDTools::UUID.random_create.to_s
      monitor.merge!({created_at_: Time.now, status_: 'active', _id: id})
      add_to_scheduler(generic_monitor(monitor))
      model.save(generic_monitor.options)
      return generic_monitor.options
    end
=begin
    def self.add(monitors)
      monitors.each do |monitor|
        id = UUIDTools::UUID.random_create.to_s
        monitor.merge!({:created_at_ => Time.now, :status_ => 'active', :_id => id})
      end
      generic_monitors  = objectify_monitors(monitors)
      model.save(monitors) unless @dont_save == true
      add_to_scheduler(generic_monitors)
    end
=end

    #def self.run(monitors)
    #  @dont_save = true
    #  add(monitors)
    #end
    def self.perform(generic_monitor)
      generic_monitor.test_command?
      model.log_results(generic_monitor)
    end
    def self.failed(test_result)
    end
    def self.resolved(test_result)
    end
=begin
    def self.perform(generic_monitor)
      generic_monitor.test_command?
      update_state(generic_monitor) unless @dont_save == true
      log_results(generic_monitor) unless @dont_save == true
    end
=end

  private
=begin
    def self.update_state(generic_monitor)
      options = {:time_of_last_test_ => generic_monitor.time_of_last_test,
                 :timestamp_ => Time.now.to_i,
               :test_result_ => generic_monitor.test_result,
              :state_ => generic_monitor.state,
              :status_ => "active" }
      generic_monitor.options.merge!(options)
      model.update(generic_monitor.options[:_id],options)
    end

   # def self.log_results(generic_monitor)
    #  logger.log(generic_monitor)
    #end

    def self.get_active_monitors_from_database
      monitors = model.active_monitors
      raise Ragios::MonitorNotFound.new(error: "No active monitor found"), "No active monitor found" if monitors.empty?
      return monitors
    end
=end
    def generic_monitor(monitor)
      GenericMonitor.new(monitor)
    end
    #def self.objectify(monitor)
    #  GenericMonitor.new(monitor)
    #end

    #def self.objectify_monitors(monitors)
    #  monitors.map { |monitor| objectify(monitor) }
    #end

    def self.is_active?(monitor)
      monitor[:status_] == "active"
    end

=begin
    def self.set_active(monitor_id)
      status = {:status_ => "active"}
      model.update(monitor_id,status)
    end

    def self.set_stopped(monitor_id)
      status = {:status_ => "stopped"}
      model.update(monitor_id,status)
    end
    def self.add_to_scheduler(generic_monitors)
      generic_monitors.each do |monitor|
        perform(monitor)
        args = {time_interval: monitor.options[:every],
                tags: monitor.options[:_id],
                object: monitor }
        scheduler.schedule(args)
      end
    end
=end
    def self.add_to_scheduler(generic_monitor)
      args = {time_interval: generic_monitor.options[:every],
                tags: generic_monitor.options[:_id],
                object: generic_monitor }
      scheduler.schedule(args)
    end
  end
end
