module Ragios
  class GenericMonitor

    attr_reader :plugin, :notifiers, :id, :test_result
    attr_reader :time_of_test, :timestamp_of_test, :options
    attr_accessor :state

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

      state :error
    end

    def initialize(options)
      @options = options
      @id = @options[:_id]
      create_plugin unless @options[:_skip_plugin]
      create_notifiers unless @options[:_skip_notifiers]
      super()
    end

    def test_command?
      @time_of_test = Time.now.utc
      @timestamp_of_test =  @time_of_test.to_i
      result = @plugin.test_command?
      @test_result = @plugin.test_result
      !!result ? fire_state_event(:success) : fire_state_event(:failure)
      return result
    rescue Exception => e
      fire_state_event(:error)
      raise e
    end

  private

    def log_event(state)
      Ragios::NotificationPublisher.new.async.log_event(
        monitor_id: generic_monitor.id,
        state: state,
        event: generic_monitor.test_result,
        time: generic_monitor.time_of_test,
        monitor: generic_monitor.options,
        type: "event",
        event_type: "monitor.#{state}"
      )
    end

    def validate_plugin
      validate_plugin_test_command
      validate_plugin_test_result
    end

    def has_failed
      log_event("failed")
    end

    def is_fixed
      log_event("resolved")
    end

    def create_notifiers
      validate_notifiers_in_options
      @options[:via] = [] << @options[:via] if @options[:via].is_a? String
      @notifiers = @options[:via].map {|notifier_name| create_notifier(notifier_name) }
    end

    def create_notifier(notifier_name)
      (Module.const_get("Ragios").const_get("Notifier").const_get(notifier_name.camelize)).new(@options)
    end

    def create_plugin
      validate_plugin_in_options
      module_name = "Plugin"
      plugin_name = @options[:plugin]
      plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize)
      plugin = plugin_class.new
      plugin.init(@options)
      validate_plugin
      @plugin = plugin
    end

    def validate_plugin_test_command
      unless @plugin.respond_to?(:test_command?)
        error_message = "No test_command? found for #{@plugin.class} plugin"
        raise Ragios::PluginTestCommandNotFound.new(error: error_message), error_message
      end
    end

    def validate_plugin_test_result
      unless defined?(@plugin.test_result)
        error_message = "No test_result found for #{@plugin.class} plugin"
        raise Ragios::PluginTestResultNotFound.new(error: error_message), error_message
      end
    end

    def validate_notifiers_in_options
      unless @options.has_key?(:via)
        error_message = "No Notifier Found in #{@options}"
        raise Ragios::NotifierNotFound.new(error: error_message), error_message
      end
    end

    def validate_plugin_in_options
      unless @options.has_key?(:plugin)
        error_message = "No Plugin Found in #{@options}"
        raise Ragios::PluginNotFound.new(error: error_message), error_message
      end
    end
  end
end