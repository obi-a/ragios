module Ragios 
  class GenericMonitor 

    attr_reader :plugin
    attr_reader :options
    attr_reader :id
    attr_reader :test_result
    attr_accessor :state
    attr_reader :time_of_last_test
    attr_reader :timestamp
    
    state_machine :state, :initial => :pending do
    
      before_transition :from => :pending, :to => :failed, :do => :has_failed
      before_transition :from => :failed, :to => :passed, :do => :is_fixed
      before_transition :from => :passed, :to => :failed, :do => :has_failed
    
      event :success do 
        transition all => :passed
      end
    
      event :failure do
        transition :passed => :failed, :pending => :failed
      end
    end
      
    def initialize(options)
      @options = options
      @id = @options[:_id]
      set_previous_state
      create_plugin
      create_notifiers
      super()  
    end
    
    def test_command
      raise Ragios::PluginTestCommandNotFound.new(error: "No test_command found for #{@plugin.class} plugin"), "No test_command found for #{@plugin.class} plugin" unless @plugin.respond_to?('test_command')
      @timestamp = Time.now.to_i
      @time_of_last_test = Time.at(@timestamp)
      state =  @plugin.test_command 
      raise Ragios::PluginTestResultNotFound.new(error: "No test_result found for #{@plugin.class} plugin"), "No test_result found for #{@plugin.class} plugin" unless defined?(@plugin.test_result)
      @test_result = @plugin.test_result
      fire_state_event(:success) if state == true
      fire_state_event(:failure) if state == false
      return state
    end

    def has_failed
      @notifiers.each do |notifier|
        NotifyJob.new.async.failed(notifier)
      end
      unless @failed.nil?
        @failed.call if @failed.lambda?
      end
      @plugin.failed if @plugin.respond_to?('failed')
    end

    def is_fixed
      @notifiers.each do |notifier|    
        NotifyJob.new.async.resolved(notifier)
      end
      unless @fixed.nil?
        @fixed.call if @fixed.lambda?
      end
      @plugin.resolved if @plugin.respond_to?('resolved')     
    end

private
    def set_previous_state
      if @options[:state_]
        @state = @options[:state_]
        @options.delete(:state_) 
      end   
    end
    
    def create_notifiers
      @notifiers = []
      raise Ragios::NotifierNotFound.new(error: "No Notifier Found"), "No Notifier Found" unless @options.has_key?(:via)
      @options[:via] = [] << @options[:via] if @options[:via].is_a? String
      @options[:via].each do |notifier|
        @notifiers << create_notifier(notifier)
      end
    end
   
    def create_notifier(notifier)
      (Module.const_get("Ragios").const_get("Notifier").const_get(notifier.camelize)).new(self)
    end
   
    def create_plugin
      raise Ragios::PluginNotFound.new(error: "No Plugin Found"), "No Plugin Found" unless @options.has_key?(:plugin)
      module_name = "Plugin"  
      plugin_name = @options[:plugin] 
      plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize) 
      plugin = plugin_class.new
      plugin.init(@options)
      @plugin = plugin
   end
 end
end
