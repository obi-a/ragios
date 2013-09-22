module Ragios 
#Translates the Ragios Domain Specific Language to the object oriented system
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
     raise Ragios::NotifierNotFound.new(error: "No Notifier included"), "No Notifier included" unless @options.has_key?(:via)
     @notifier = (Module.const_get("Ragios").const_get("Notifier").const_get(options[:via].camelize)).new(self)
   end
 end
end
