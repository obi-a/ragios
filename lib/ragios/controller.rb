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

  def self.init(args)
    @scheduler = args[:scheduler]
  end

  def self.stop_monitor(id)
    @scheduler.stop_monitor(id)
  end

  def self.delete_monitor(id)
    begin 
      auth_session = Ragios::DatabaseAdmin.session
      monitor = Couchdb.view({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)    
      stop_monitor(id) if(monitor["state"] == "active")
      Couchdb.delete_doc({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)
    rescue CouchdbException => e
       e.error
    end
  end

  def self.update_monitor(id, options)
    auth_session = Ragios::DatabaseAdmin.session
    doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => options}   
    Couchdb.update_doc doc,auth_session
    monitor = Couchdb.view( {:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)
    if(monitor["state"] == "active")
      stop_monitor(id)
      restart_monitor(id)
    end
  end

  #returns a list of all active monitors in the database
   def self.get_active_monitors
     view = {:database => Ragios::DatabaseAdmin.monitors,
                :design_doc => 'monitors',
                   :view => 'get_active_monitors',
                         :json_doc => $path_to_json + '/get_monitors.json'}
     monitors = Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
     raise Ragios::MonitorNotFound.new(error: "No active monitor found"), "No active monitor found" if monitors.empty?
     return monitors
   end

   def self.get_monitor(id)
     doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => id}
     Couchdb.view doc, Ragios::DatabaseAdmin.session
   end

   def self.get_all_monitors
     view = {:database => Ragios::DatabaseAdmin.monitors,
        :design_doc => 'monitors',
         :view => 'get_monitors',
          :json_doc => $path_to_json + '/get_monitors.json'}

     Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
   end

  def self.get_monitors(tag = nil)
      @scheduler.get_monitors(tag)
  end

  def self.get_monitors_frm_scheduler(tag = nil)
    if (tag.nil?)
      @scheduler.get_monitors
    else
      @scheduler.get_monitors(tag)
    end
  end

  def self.get_stats(tag = nil)
    auth_session = Ragios::DatabaseAdmin.session
    if(tag.nil?)
      view = {:database => Ragios::DatabaseAdmin.monitors,
        		:design_doc => 'get_stats',
         		:view => 'get_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
      Couchdb.find_on_fly(view,auth_session)  
     else
       view = {:database => Ragios::DatabaseAdmin.monitors,
        		:design_doc => 'get_stats',
         		:view => 'get_tag_and_mature_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
       Couchdb.find_on_fly(view, auth_session, key = tag)
     end
  end
 
  def self.restart monitors
    @scheduler.restart monitors 
  end

  def self.start monitors 
    @scheduler.create monitors
    @scheduler.start 
  end

  def self.restart_monitor(id)
    monitors = Ragios::Server.find_monitors(:_id => id)
    raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{id}" if monitors.empty?
    return monitors[0] if monitors[0]["state"] == "active"
    set_active(id)
    start_monitors(monitors.transform_keys_to_symbols,server='restart')
  end
  
  def self.restart_monitors
    monitors = Ragios::Server.get_active_monitors
    start_monitors(monitors.transform_keys_to_symbols,server='restart')
  end

  def self.add_monitors(monitors)
    start_monitors(monitors,server= "start")
  end

  def self.run_monitors(monitors)
    start_monitors(monitors)
  end

private

  def self.create_monitors(monitoring)
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

  def self.start_monitors(monitoring, server = nil)
    monitors = create_monitors(monitoring) 
    if server == 'start'
      Ragios::Server.start monitors
    elsif server == 'restart'
      Ragios::Server.restart monitors
    else
      start_monitors_on_Core(monitors) 
    end
  end 

  def self.set_active(id)
    data = {:state => "active"}
    doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => data}   
    Couchdb.update_doc doc, Ragios::DatabaseAdmin.session
  end

  def self.start_monitors_on_Core(monitoring)
    @ragios = Ragios::Schedulers::RagiosScheduler.new monitoring
    @ragios.init
    @ragios.start 
    @ragios.get_monitors    
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
