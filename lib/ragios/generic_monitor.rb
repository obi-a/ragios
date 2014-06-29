module Ragios
  class GenericMonitor

    attr_reader :plugin
    attr_reader :notifiers
    attr_reader :options
    attr_reader :id
    attr_reader :test_result
    attr_accessor :state
    attr_reader :time_of_test
    attr_reader :timestamp_of_test
    #attr_reader :fail_tolerance
    #attr_reader :failures
    #attr_reader :failure_notified

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
      create_plugin
      create_notifiers
      super()
    end
=begin
    def initialize(options)
      @options = options
      @id = @options[:_id]
      set_previous_state
      @failures  = 0
      @fail_tolerance = @options[:fail_tolerance].to_i
      @failure_notified = false
      create_plugin
      create_notifiers
      super()
    end
=end

    def test_command?
      raise Ragios::PluginTestCommandNotFound.new(error: "No test_command? found for #{@plugin.class} plugin"), "No test_command? found for #{@plugin.class} plugin" unless @plugin.respond_to?('test_command?')
      @timestamp_of_test = Time.now.to_i
      @time_of_test = Time.at(@timestamp)
      passed_or_failed = !!@plugin.test_command?
      raise Ragios::PluginTestResultNotFound.new(error: "No test_result found for #{@plugin.class} plugin"), "No test_result found for #{@plugin.class} plugin" unless defined?(@plugin.test_result)
      @test_result = @plugin.test_result
      passed_or_failed ? fire_state_event(:success) : fire_state_event(:failure)
      return passed_or_failed
    end

private
    def has_failed
      @notifiers.each do |notifier|
        NotifyJob.new.async.failed(@options, @test_result, notifier)
      end
    end
    def is_fixed
      @notifiers.each do |notifier|
        NotifyJob.new.async.resolved(@options, @test_result, notifier)
      end
    end
=begin
    def increment_failure_count!
      @failures +=  1
    end
    def reset_failure_count!
      @failures = 0
      @failure_notified = false
    end
    def exceed_failure_tolerance
      @failures > fail_tolerance
    end
    def has_failed
      increment_failure_count!
      if exceed_failure_tolerance
        unless @failure_notified
          @notifiers.each do |notifier|
            NotifyJob.new.async.failed(@test_result, notifier)
            @failure_notified = true
          end
        end
      end
    end

    def is_fixed
      reset_failure_count!
      @notifiers.each do |notifier|
        NotifyJob.new.async.resolved(@test_result, notifier)
      end
    end

    def set_previous_state
      if @options[:state_]
        @state = @options[:state_]
        @options.delete(:state_)
      end
    end
=end
    def create_notifiers
      raise Ragios::NotifierNotFound.new(error: "No Notifier Found in #{@options}"), "No Notifier Found in #{@options}" unless @options.has_key?(:via)
      @options[:via] = [] << @options[:via] if @options[:via].is_a? String
      @notifiers = @options[:via].map {|notifier_name| create_notifier(notifier_name) }
    end

    def create_notifier(notifier_name)
      (Module.const_get("Ragios").const_get("Notifier").const_get(notifier_name.camelize)).new(@options)
    end

    def create_plugin
      raise Ragios::PluginNotFound.new(error: "No Plugin Found in #{@options}"), "No Plugin Found in #{@options}" unless @options.has_key?(:plugin)
      module_name = "Plugin"
      plugin_name = @options[:plugin]
      plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize)
      plugin = plugin_class.new
      plugin.init(@options)
      @plugin = plugin
   end
 end
end
