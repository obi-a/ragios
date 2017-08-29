module Ragios
  module Monitors
    class GenericMonitor

      attr_reader :plugin, :notifiers, :id, :test_result
      attr_reader :time_of_test, :options
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
        def find(monitor_id, skip_extensions_creation = false)
          monitor = model.find(monitor_id)
          if monitor[:type] != "monitor"
            raise_monitor_not_found(monitor_id)
          end
          current_state  =  model.get_monitor_state(monitor_id)
          generic_monitor = GenericMonitor.new(monitor, skip_extensions_creation)
          generic_monitor.state = current_state[:state] if current_state[:state]
          generic_monitor
        rescue Leanback::CouchdbException => e
          handle_couchdb_error(monitor_id, e)
        end

        def build_extension(extension_type, extension_name)
          extension_module =
            case extension_type
            when :plugin
              Ragios::Plugin
            when :notifier
              Ragios::Notifier
            else
              error_message = "Unidentified Extension Type #{extension_type}"
              raise Ragios::UnIdentifiedExtensionType.new(error_message), error_message
            end

          extension_module.const_get("#{extension_name.to_s.camelize}", false).new
        rescue => e
          raise $!, "Cannot Create #{extension_type} #{extension_name}: #{$!}", $!.backtrace
        end

      private
        def model
          @model ||= Ragios::Database::Model.new
        end

        def raise_monitor_not_found(monitor_id)
          error_message = "No monitor found with id = #{monitor_id}"
          raise Ragios::MonitorNotFound.new(error: "No monitor found"), error_message
        end

        def handle_couchdb_error(monitor_id, couchdb_exception)
          if couchdb_exception.response[:error] == "not_found"
            raise_monitor_not_found(monitor_id)
          else
            raise couchdb_exception
          end
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
        create_plugin unless defined?(@plugin)
        @time_of_test = Time.now.utc
        result = @plugin.test_command?
        @test_result = @plugin.test_result
        result ? fire_state_event(:success) : fire_state_event(:failure)
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
        event_details
      end

      def has_failed
        push_event("failed")
      end

      def is_fixed
        push_event("resolved")
      end

      def create_notifiers
        raise_notifier_not_found unless @options.has_key?(:via)
        @options[:via] = [] << @options[:via] if @options[:via].is_a? String
        raise_notifier_not_found if @options[:via].empty?
        @notifiers = @options[:via].map do |notifier_name|
          notifier = GenericMonitor.build_extension(:notifier, notifier_name)
          validate_notifier(notifier)
          notifier.init(@options)
          notifier
        end
      end

      def create_plugin
        raise_plugin_not_found unless @options.has_key?(:plugin)
        plugin = GenericMonitor.build_extension(:plugin, @options[:plugin])
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

      def validate_notifier(notifier)
        if !notifier.respond_to?(:init)
          error_message = "init not implemented in #{notifier.class} notifier"
          raise Ragios::NotifierInitNotImplemented.new(error: error_message), error_message
        elsif !notifier.respond_to?(:failed)
          error_message = "failed not implemented in #{notifier.class} notifier"
          raise Ragios::NotifierFailedNotImplemented.new(error: error_message), error_message
        elsif !notifier.respond_to?(:resolved)
          error_message = "resolved not implemented in #{notifier.class} notifier"
          raise Ragios::NotifierResolvedNotImplemented.new(error: error_message), error_message
        else
          true
        end
      end

      def raise_notifier_not_found
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
