module Ragios
class Controller

  def self.scheduler(sch = nil)    
    @scheduler ||= sch
  end
  
  def self.model(m = nil)    
    @model ||= m
  end

  def self.stop_monitor(id)
    scheduler.stop_monitor(id)
  end

  def self.delete_monitor(id)
    monitor = model.find(id)
    stop_monitor(id) if(monitor["state"] == "active")
    model.delete(id)
  end

  def self.update_monitor(id, options)
    model.update(id,options)
    monitor = model.find(id)
    if(monitor["state"] == "active")
      stop_monitor(id)
      restart_monitor(id)
    end
  end

  #returns a list of all active monitors in the database
   def self.get_active_monitors
     monitors = model.active_monitors
     raise Ragios::MonitorNotFound.new(error: "No active monitor found"), "No active monitor found" if monitors.empty?
     return monitors
   end

   def self.get_monitor(id)
     model.find(id)
   end

   def self.get_all_monitors
     model.all
   end

  def self.get_monitors(tag = nil)
    scheduler.get_monitors(tag)
  end

  def self.get_monitors_frm_scheduler(tag = nil)
    if (tag.nil?)
      scheduler.get_monitors
    else
      scheduler.get_monitors(tag)
    end
  end

  def self.get_stats(tag = nil)
    model.stats(tag)
  end

  def self.restart_monitor(id)
    monitors = find_monitors(:_id => id)
    raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{id}" if monitors.empty?
    return monitors[0] if monitors[0]["state"] == "active"
    set_active(id)
    restart_monitors_on_server(objectify_monitors(monitors.transform_keys_to_symbols))
  end

  def self.find_monitors(options) 
    model.where(options)
  end
  
  def self.restart_monitors
    monitors_hash = get_active_monitors
    monitors = objectify_monitors(monitors_hash.transform_keys_to_symbols)
    restart_monitors_on_server(monitors)
  end

  def self.add_monitors(monitors_hash)
    monitors  = objectify_monitors(monitors_hash)
    start_monitors_on_server(monitors)
    model.save(monitors_hash)
  end

  def self.run_monitors(monitors_hash)
    monitors = objectify_monitors(monitors_hash)
    start_monitors_on_core(monitors)
  end

private

  def self.objectify_monitors(monitoring)
    @monitors = []
    monitoring.each do|options|   
      ragios_monitor = GenericMonitor.new(options) 
      @monitors << ragios_monitor
    end 
    @monitors
  end

  def self.set_active(id)
    model.set_active(id)
  end

  def self.restart_monitors_on_server(monitors)
    scheduler.restart monitors 
  end

  def self.start_monitors_on_server(monitors) 
    scheduler.monitors = monitors
    scheduler.start 
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
