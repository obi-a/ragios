module Ragios
  module Monitors
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

        event :error do
          transition all => :error
        end

        state :error
      end

      def initialize(options)
        puts "these are the options #{options.inspect}"
        @options = options
        @id = @options[:_id]
        create_plugin
        create_notifiers
        super()
      end

      def test_command?
        puts "generic monitor previous state #{@state}"
        @time_of_test = Time.now.utc
        @timestamp_of_test =  @time_of_test.to_i
        result = @plugin.test_command?
        @test_result = @plugin.test_result
        result ? fire_state_event(:success) : fire_state_event(:failure)
        puts "generic monitor new state #{@state}"
        return result
      rescue Exception => e
        fire_state_event(:error)
        raise e
      end

    private

      def push_event(state)
        event_details = {
          monitor_id: @id,
          state: state,
          event: @test_result,
          time: @time_of_test,
          monitor: @options,
          type: "event",
          event_type: "monitor.#{state}"
        }
        pusher = Ragios::Notifications::Pusher.new
        pusher.push(JSON.generate(event_details))
        pusher.terminate
      end

      def validate_plugin
        validate_plugin_test_command
        validate_plugin_test_result
      end

      def has_failed
        push_event("failed")
      end

      def is_fixed
        push_event("resolved")
      end

      def create_notifiers
        validate_notifiers_in_options
        @options[:via] = [] << @options[:via] if @options[:via].is_a? String
        raise_notifier_not_found_error if @options[:via].empty?
        @notifiers = @options[:via].map {|notifier_name| create_notifier(notifier_name) }
      end

      def create_notifier(notifier_name)
        (Module.const_get("Ragios").const_get("Notifier").const_get(notifier_name.camelize)).new(@options)
      rescue => e
        raise $!, "Cannot Create Notifier #{notifier_name}: #{$!}", $!.backtrace
      end

      def create_plugin
        validate_plugin_in_options
        plugin = build_plugin(@options[:plugin])
        plugin.init(@options)
        @plugin = plugin
        validate_plugin
      end

      def build_plugin(plugin_name)
        module_name = "Plugin"
        plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.camelize)
        plugin_class.new
      rescue => e
        raise $!, "Cannot Create Plugin #{plugin_name}: #{$!}", $!.backtrace
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
          raise_notifier_not_found_error
        end
      end

      def raise_notifier_not_found_error
        error_message = "No Notifier Found in #{@options}"
        raise Ragios::NotifierNotFound.new(error: error_message), error_message
      end

      def validate_plugin_in_options
        unless @options.has_key?(:plugin)
          error_message = "No Plugin Found in #{@options}"
          raise Ragios::PluginNotFound.new(error: error_message), error_message
        end
      end
    end
  end
end
