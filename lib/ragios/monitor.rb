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

module Ragios 
#Translates the Ragios Domain Specific Language to the object oriented system

module InitValues
 def ragios_init_values(options)
  #translate values of the DSL to a Ragios::Monitors::System object
  @time_interval = options[:every]
  
  options[:notify_interval] = '6h' if options[:notify_interval].nil?

  @notification_interval = options[:notify_interval]
  @contact = options[:contact]
  @test_description = options[:test]
  @notifier = options[:via]

   #if tag exists assign it
  @tag = options[:tag] unless options[:tag].nil?
   
  #assumes that options[:fixed] and options[failed] are code lambdas when available
  @fixed =  options[:fixed] unless options[:fixed].nil?
  @failed = options[:failed] unless options[:failed].nil?
 end 
end

class Monitor

    def self.update_status config
     Ragios::System.update_status config 
    end

    def self.get_monitors
      Ragios::System.get_monitors 
    end  

   def self.set_active(id)
     data = {:state => "active"}
     doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => data}   
     Couchdb.update_doc doc, Ragios::DatabaseAdmin.session
   end

  def self.restart_monitor(id)
    monitors = Ragios::Server.find_monitors(:_id => id)
    raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{id}" if monitors.empty?
    return monitors[0] if monitors[0]["state"] == "active"
    set_active(id)
    monitors.transform_keys_to_symbols
    start monitors,server='restart' 
  end

  def self.restart_monitors
    monitors = Ragios::Server.get_active_monitors
    monitors.transform_keys_to_symbols
    start monitors,server='restart' 
  end

  def self.start(monitoring, server = nil)
        monitors = []
        monitoring.each do|options|
         #create the right type of monitor instance for each monitor and send it to the scheduler    
         module_name = "Monitors"  
         plugin_name = options[:monitor] 
         plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize)
         #add method to plugin class that will translate options to real values
         plugin_class.class_eval do |options|
           include InitValues 
         end     
         plugin = plugin_class.new
         plugin.init(options)
         #add method to GenericMonitor class that will translate options to real values
         GenericMonitor.class_eval do |options|
           include InitValues
         end
         ragios_monitor = GenericMonitor.new(plugin,options) 
         monitors << ragios_monitor
        end #end of each...do loop
        
        if server == true
          Ragios::Server.start monitors
        elsif server == 'restart'
          Ragios::Server.restart monitors
        else
          Ragios::System.start monitors 
        end
    end   
 end

class GenericMonitor < Ragios::Monitors::System

      attr_reader :plugin
      attr_reader :options
      attr_accessor :id
      attr_accessor :tag
      attr_accessor :status
      attr_accessor :was_down
      #attr_accessor :state

      #create the right type of monitor instance
    def initialize(plugin,options)
        @plugin = plugin
        @plugin.ragios_init_values(options)
        ragios_init_values(options)
        @describe_test_result = ''
        if defined?(@plugin.describe_test_result) 
          @describe_test_result = @plugin.describe_test_result 
        else
          raise '@describe_test_result must be defined in ' + @plugin.to_s
        end   
        @options = options #to be used by the server scheduler 
        create_notifier    
        super()
    end

    def create_notifier
      raise Ragios::NotifierNotFound.new(error: "No Notifier included"), "No Notifier included" unless @options.has_key?(:via)
      @notifier = (Module.const_get("Ragios").const_get("Notifier").const_get(options[:via].camelize)).new(self)
    end
    
    def test_command
        if @plugin.respond_to?('test_command')
           status =  @plugin.test_command 
           if defined?(@plugin.test_result)
             @test_result = @plugin.test_result
           else
             raise '@test_result must be defined in ' + @plugin.to_s
           end
        end
        return status
    end

    def failed
      unless @failed.nil?
       @failed.call if @failed.lambda?
      end
      @plugin.failed if @plugin.respond_to?('failed')
    end
     
    def notify
      @notifier.notify if @notifier.respond_to?('notify')
    end

    def fixed
      @notifier.resolved
      unless @fixed.nil?
        @fixed.call if @fixed.lambda?
      end
    end
 end
end
