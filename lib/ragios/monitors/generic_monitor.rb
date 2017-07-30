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

      class << self
        def find(monitor_id)
          monitor = model.find(monitor_id)
          current_state  =  model.get_monitor_state(monitor_id)
          generic_monitor = GenericMonitor.new(monitor)
          generic_monitor.state = current_state[:state]
          generic_monitor
        end

        def build_plugin(plugin_name)
          module_name = "Plugin"
          plugin_class = Module.const_get("Ragios").const_get(module_name).const_get(plugin_name.to_s.camelize)
          plugin_class.new
        rescue => e
          raise $!, "Cannot Create Plugin #{plugin_name}: #{$!}", $!.backtrace
        end

        def build_notifier(notifier_name, options)
          (Module.const_get("Ragios").const_get("Notifier").const_get(notifier_name.camelize)).new(options)
        rescue => e
          raise $!, "Cannot Create Notifier #{notifier_name}: #{$!}", $!.backtrace
        end

        private def model
          @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
        end
      end

      def initialize(options, skip_extensions_creation = false)
        @options = options
        @id = @options[:_id]
        unless skip_extensions_creation
          create_plugin
          create_notifiers
        end
        super()
      end

      def test_command?
        p "generic monitor previous state #{@state}"
        @time_of_test = Time.now.utc
        @timestamp_of_test =  @time_of_test.to_i
        result = @plugin.test_command?
        @test_result = @plugin.test_result
        result ? fire_state_event(:success) : fire_state_event(:failure)
        p "generic monitor new state #{@state}"
        result
      rescue Exception => e
        fire_state_event(:error)
        raise e
      end

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
        true
      end

      def has_failed
        push_event("failed")
      end

      def is_fixed
        push_event("resolved")
      end

      def create_notifiers
        raise_notifier_not_found_error unless @options.has_key?(:via)
        validate_notifiers_in_options
        @options[:via] = [] << @options[:via] if @options[:via].is_a? String
        raise_notifier_not_found_error if @options[:via].empty?
        @notifiers = @options[:via].map do |notifier_name|
          GenericMonitor.build_notifier(notifier_name, @options)
        end
      end

      def create_plugin
        raise_plugin_not_found unless @options.has_key?(:plugin)
        plugin = GenericMonitor.build_plugin(@options[:plugin])
        validate_plugin(plugin)
        plugin.init(@options)
        @plugin = plugin
      end

    private

      def validate_plugin(plugin)
        if !plugin.respond_to?(:test_command?)
          error_message = "test_command? not implemented in #{plugin.class} plugin"
          raise Ragios::PluginTestCommandNotImplemented.new(error: error_message), error_message
        elsif !plugin.respond_to?(:init)
          error_message = "init not implemented in #{plugin.class} plugin"
          raise Ragios::PluginInitNotImplemented.new(error: error_message), error_message
        elsif !defined?(plugin.test_result)
          error_message = "test_result not defined in #{plugin.class} plugin"
          raise Ragios::PluginTestResultNotDefined.new(error: error_message), error_message
        else
          true
        end
      end

      def raise_notifier_not_found_error
        error_message = "No Notifier Found in #{@options}"
        raise Ragios::NotifierNotFound.new(error: error_message), error_message
      end

      def raise_plugin_not_found
        error_message = "No Plugin Found in #{@options}"
        raise Ragios::PluginNotFound.new(error: error_message), error_message
      end
    end
  end
end
