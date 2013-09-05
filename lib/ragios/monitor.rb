class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end


module Ragios 
#Translates the Ragios Domain Specific Language to the object oriented system

module Notifiers
 def notify
     
     if @notifier == 'email'
        email_notify
     elsif @notifier == 'gmail'
        gmail_notify
     elsif @notifier == 'ses'
        ses_notify
     elsif @notifier == 'twitter'
       tweet_notify
     else 
       raise 'Notifier: Not Found'
     end      
 end
                
 def fixed
  #execute the code block if provided
  unless @fixed.nil?
   @fixed.call if @fixed.lambda?
  end

  if @notifier == 'email'
    email_resolved
  elsif @notifier == 'gmail'
    gmail_resolved
   elsif @notifier == 'ses'
    ses_resolved
  elsif @notifier == 'twitter'
    tweet_resolved
  else 
     raise 'Notifier: Not Found'
  end
 end    
end

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

   #create and restart all monitors from database 
   def self.restart(id = nil)
     #read off all monitors from database 
     if(id == nil) 
       monitors = Ragios::Server.get_active_monitors
       raise "monitor not found" if monitors.empty?
     else 
       monitors = Ragios::Server.find_monitors(:_id => id)
       if monitors == []
          raise "monitor not found"
       elsif monitors[0]["state"] == "active"
          #monitor is already active
          return monitors[0]
       end
       data = {:state => "active"}
       doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => data}   
       Couchdb.update_doc doc,Ragios::DatabaseAdmin.session
     end
     count = 0
     monitors.each do |monitor|
     monitor = Hash.transform_keys_to_symbols(monitor)
       monitors[count] = monitor
       count +=  1
     end
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
        super()
    end

    def notifier(options)
      notifier_name = options[:via]
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
    end
     
  @plugin.failed if @plugin.respond_to?('failed')

  include Notifiers
 end
end
