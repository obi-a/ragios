module Ragios
class Controller

  def self.scheduler(sch = nil)    
    @scheduler ||= sch
  end
  
  def self.model(m = nil)    
    @model ||= m
  end

  def self.stop_monitor(monitor_id)
    scheduler.stop(monitor_id)
    set_stopped(monitor_id)
  end

  def self.delete_monitor(monitor_id)
    monitor = model.find(monitor_id)
    stop_monitor(monitor_id) if is_active?(monitor)
    model.delete(monitor_id)
  end

  def self.update_monitor(monitor_id, options)
    model.update(monitor_id,options)
    monitor = model.find(monitor_id)
    if is_active?(monitor)
      stop_monitor(monitor_id)
      restart_monitor(monitor_id)
    end
  end

   def self.get_monitor(monitor_id)
     model.find(monitor_id)
   end

   def self.get_all_monitors
     model.all
   end

  def self.restart_monitor(monitor_id)
    monitors = find_monitors(:_id => monitor_id)
    raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{id}" if monitors.empty?
    return monitors[0] if is_active?(monitors[0])
    set_active(monitor_id)
    generic_monitors = objectify_monitors(monitors.transform_keys_to_symbols)
    add_to_Scheduler(generic_monitors)
  end
  
  def self.test_now(monitor_id)
    monitor = model.find(monitor_id)
    generic_monitor = objectify(monitor)
    perform(generic_monitor)
  end

  def self.find_monitors(options) 
    model.where(options)
  end
  
  def self.restart_monitors
    monitors = get_active_monitors_from_database
    generic_monitors = objectify_monitors(monitors.transform_keys_to_symbols)
    add_to_scheduler(generic_monitors)
  end

  def self.add_monitors(monitors)
    monitors =  model.save(monitors)
    generic_monitors  = objectify_monitors(monitors)
    add_to_scheduler(generic_monitors)
  end

  def self.run_monitors(monitors)
    generic_monitors = objectify_monitors(monitors)
    start_monitors_on_core(generic_monitors)
  end
  
  def self.perform(generic_monitor)
    puts "we outchea"
  end
  

private

  def self.get_active_monitors_from_database
    monitors = model.active_monitors
    raise Ragios::MonitorNotFound.new(error: "No active monitor found"), "No active monitor found" if monitors.empty?
    return monitors
  end
  
  def self.objectify(options)
  	GenericMonitor.new(options) 
  end

  def self.objectify_monitors(monitors)
    generic_monitors = []
    monitors.each do|options|   
			generic_monitors << objectify(options)
    end 
    generic_monitors
  end
  
  def self.is_active?(monitor)
  	monitor["state"] == "active"
  end

  def self.set_active(monitor_id)
    state = {:state => "active"}
    model.update(monitor_id,state)
  end
  
  def self.set_stopped(monitor_id)
  	state = {:state => "stopped"}
    model.update(monitor_id,state)
  end

  def self.add_to_scheduler(generic_monitors)
    scheduler.restart generic_monitors 
    generic_monitors.each do |monitor|
    	args = {time_interval: monitor.options[:every],
              tags: monitor.options[:_id],
              object: self }
    	scheduler.schedule(args)
    end
  end

  def self.start_monitors_on_core(monitors)
    scheduler.monitors = monitors
    scheduler.init
    scheduler.start 
    scheduler.get_monitors    
  end
 end
end

class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end

class Array
  def transform_keys_to_symbols
    count = 0
    self.each do |hash|
      hash = Hash.transform_keys_to_symbols(hash)
      self[count] = hash
      count +=  1
    end
    self
  end
end
