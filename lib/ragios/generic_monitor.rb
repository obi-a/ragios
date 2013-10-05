module Ragios 
	class GenericMonitor 

  	attr_reader :plugin
  	attr_reader :options
  	attr_reader :id
  	#attr_accessor :tag
  	attr_accessor :status
  	attr_accessor :was_down
  	attr_accessor :state

      
    def initialize(options)
      @options = options
      create_plugin 
      create_notifier    
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

private
   def create_notifier
     raise Ragios::NotifierNotFound.new(error: "No Notifier Found"), "No Notifier Found" unless @options.has_key?(:via)
     @notifier = (Module.const_get("Ragios").const_get("Notifier").const_get(@options[:via].camelize)).new(self)
   end
   
   def create_plugin
     raise Ragios::PluginNotFound.new(error: "No Plugin Found"), "No Notifier Found" unless @options.has_key?(:monitor)
     module_name = "Monitors"  
     plugin_name = @options[:monitor] 
     plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize) 
     plugin_class.new
     plugin.init(@options)
     @plugin  = plugin
   end
 end
end
