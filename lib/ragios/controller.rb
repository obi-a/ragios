module Ragios
module InitValues
 def ragios_init_values(options)
  #translate values of the DSL to a Ragios::Monitors::System object
  @time_interval = options[:every]
  
  options[:notify_interval] = '6h' if options[:notify_interval].nil?

  @notification_interval = options[:notify_interval]
  @contact = options[:contact]
  @test_description = options[:test]
  #@notifier = options[:via]

   #if tag exists assign it
  @tag = options[:tag] unless options[:tag].nil?
   
  #assumes that options[:fixed] and options[failed] are code lambdas when available
  @fixed =  options[:fixed] unless options[:fixed].nil?
  @failed = options[:failed] unless options[:failed].nil?
 end 
end

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
  end

  def self.run_monitors(monitors_hash)
    monitors = objectify_monitors(monitors_hash)
    start_monitors_on_core(monitors)
  end

private

  def self.objectify_monitors(monitoring)
    monitors = []
    monitoring.each do|options|   
      module_name = "Monitors"  
      plugin_name = options[:monitor] 
      plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize)
      plugin_class.class_eval do |options|
        include InitValues 
      end     
      plugin = plugin_class.new
      plugin.init(options)
      GenericMonitor.class_eval do |options|
        include InitValues
      end
      ragios_monitor = GenericMonitor.new(plugin,options) 
      monitors << ragios_monitor
    end 
    monitors
  end

  def self.set_active(id)
    model.set_active(id)
  end

  def self.restart_monitors_on_server(monitors)
    scheduler.restart monitors 
  end

  def self.start_monitors_on_server(monitors) 
    scheduler.create monitors
    scheduler.start 
  end

  def self.start_monitors_on_core(monitors)
    scheduler.create monitors
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
