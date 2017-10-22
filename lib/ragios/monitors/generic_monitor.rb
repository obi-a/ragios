module Ragios
  module Monitors
    class GenericMonitor

      attr_reader :plugin, :notifiers, :id, :test_result, :interval
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
          monitor = try_monitor(monitor_id) do
            model.find(monitor_id)
          end

          if monitor[:type] != "monitor"
            raise_monitor_not_found(monitor_id)
          end
          generic_monitor = GenericMonitor.new(monitor, skip_extensions_creation)
          generic_monitor.send :current_state, model.get_monitor_state(monitor_id)
          generic_monitor
        end

        def create(opts)
          options = opts.merge({created_at_: Time.now.utc, status_: 'active', type: "monitor"})
          generic_monitor = GenericMonitor.new(options)
          generic_monitor.save
          generic_monitor.schedule
          generic_monitor
        end

        def stop(monitor_id)
          unschedule(monitor_id)
          try_monitor(monitor_id) do
            model.update(monitor_id, status_: "stopped")
          end
        end

        def start(monitor_id)
          generic_monitor = GenericMonitor.find(monitor_id)
          reschedule(generic_monitor.id, generic_monitor.interval)
          model.update(generic_monitor.id, status_: "active")
          true
        end

        def delete(monitor_id)
          unschedule(monitor_id)
          try_monitor(monitor_id) do
            model.delete(monitor_id)
          end
        end

        def update(monitor_id, options)
          if options.keys.any? { |key| [:type, :status_, :created_at_, :creation_timestamp_, :current_state_, :_id].include?(key) }
            message = "Cannot edit system settings"
            raise Ragios::CannotEditSystemSettings.new(error: message), message
          end
          try_monitor(monitor_id) do
            old_monitor = model.find(monitor_id)
            new_monitor = old_monitor.merge(options)
            generic_monitor = GenericMonitor.new(new_monitor)
            model.update(generic_monitor.id, options)
          end
          reschedule(monitor_id, options[:every]) if options.keys.include?(:every)
          true
        end

        def trigger(monitor_id)
          try_monitor(monitor_id) do
            monitor = model.find(monitor_id)
            add_to_scheduler(monitor_id: monitor[:_id], perform: :trigger_work)
            true
          end
        end

        def build_extension(extension_type, extension_name)
          extension_module =
            case extension_type
            when :plugin
              Ragios::Plugins
            when :notifier
              Ragios::Notifiers
            else
              error_message = "Unidentified Extension Type #{extension_type}"
              raise Ragios::UnIdentifiedExtensionType.new(error_message), error_message
            end

          extension_module.const_get("#{camelize(extension_name.to_s)}", false).new
        rescue => e
          raise $!, "Cannot Create #{extension_type} #{extension_name}: #{$!}", $!.backtrace
        end

        def add_to_scheduler(options)
          pusher = Ragios::RecurringJobs::Pusher.new
          pusher.push(JSON.generate(options))
          pusher.terminate
        end

        def model
          @model ||= Ragios::Database::Model.new
        end

        def schedule(monitor_id, interval, perform = :schedule_and_run_later)
          add_to_scheduler({
            monitor_id: monitor_id,
            interval: interval,
            perform: perform
          })
        end

        def reschedule(monitor_id, interval)
          add_to_scheduler({
            monitor_id: monitor_id,
            interval: interval,
            perform: :reschedule
          })
        end

        def unschedule(monitor_id)
          add_to_scheduler({
            monitor_id: monitor_id,
            perform: :unschedule
          })
        end

      private

        def camelize(str)
          str.split('_').collect(&:capitalize).join
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

        def try_monitor(monitor_id)
          yield
        rescue Leanback::CouchdbException => e
          handle_couchdb_error(monitor_id, e)
        end
      end

      def initialize(options, skip_extensions_creation = false)
        @options = options
        @id = @options[:_id] if options[:_id]
        @interval = @options[:every]
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

      def save
        unless defined?(@id)
          @id = SecureRandom.uuid
          @options.merge!(_id: @id)
        end
        GenericMonitor.model.save(@id, @options)
      end

      def schedule
        GenericMonitor.add_to_scheduler({
          monitor_id: @id,
          interval: @interval,
          perform: :run_now_and_schedule
        })
      end

    private

      def current_state(results)
        @state = results[:state] if results[:state]
        @test_result = results[:event]
        @time_of_test = results[:time]
        @options[:current_state] = {
          state: @state,
          test_result: @test_result,
          time_of_test: @time_of_test
        }
      end

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
