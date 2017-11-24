module Ragios
  module Monitors
    class Manager
      #see contracts: https://github.com/egonSchiele/contracts.ruby
      include Contracts

      #types
      Monitor = Hash
      Monitor_id = String

      attr_reader :model

      Contract Hash => Monitor
      def add(options)
        generic_monitor = GenericMonitor.create(options)
        log_monitor(:create, generic_monitor.id)
        log_monitor(:start, generic_monitor.id)
        generic_monitor.options
      end

      Contract Monitor_id, Bool => Monitor
      def get(monitor_id)
        GenericMonitor.find(monitor_id).options
      end

      Contract Monitor_id => Bool
      def stop(monitor_id)
        GenericMonitor.stop(monitor_id)
        log_monitor(:stop, monitor_id)
        true
      end

      Contract Monitor_id => Bool
      def delete(monitor_id)
        GenericMonitor.delete(monitor_id)
        log_monitor(:delete, monitor_id)
        true
      end

      Contract Monitor_id, Hash => Bool
      def update(monitor_id, options)
        GenericMonitor.update(monitor_id, options)
        log_monitor(:update, monitor_id, update: options)
        true
      end

      Contract Monitor_id => Bool
      def start(monitor_id)
        GenericMonitor.start(monitor_id)
        log_monitor(:start, monitor_id)
        true
      end

      Contract Monitor_id => Bool
      def test_now(monitor_id)
        GenericMonitor.trigger(monitor_id)
        true
      end

      #queries
      Contract Any => ArrayOf[Monitor]
      def get_all(options = {})
        model.all_monitors(options)
      end

      Contract Monitor_id, String, Hash => ArrayOf[Hash]
      def get_events_by_state(monitor_id, state, options)
        model.get_monitor_events_by_state(monitor_id, state, options)
      end

      Contract Monitor_id, String, Hash => ArrayOf[Hash]
      def get_events_by_type(monitor_id, event_type, options)
        model.get_monitor_events_by_type(monitor_id, event_type, options)
      end

      Contract Monitor_id, Hash => ArrayOf[Hash]
      def get_events(monitor_id, options)
        model.get_monitor_events(monitor_id, options)
      end

      Contract Hash => ArrayOf[Monitor]
      def where(options)
        model.monitors_where(options)
      end

      Contract Monitor_id => Hash
      def get_current_state(monitor_id)
        model.get_monitor_state(monitor_id)
      end

    private unless $TESTING

      def model
        @model ||= Ragios::Database::Model.new
      end

      def pusher
        Ragios::Events::Pusher.new
      end

      def log_monitor(event, monitor_id, options = {})
        opts = case event
              when :start
                {
                  type: "start",
                  state: "started",
                  status: "started"
                }
              when :create
                {
                  type: "create",
                  state: "create",
                  status: "created"
                }
              when :stop
                {
                  type: "stop",
                  state: "stopped",
                  status: "stopped"
                }
              when :delete
                {
                  type: "delete",
                  state: "deleted",
                  status: "deleted"
                }
              when :update
                {
                  type: "update",
                  state: "updated",
                  status: "updated"
                }
              end

        event_details = {
          monitor_id: monitor_id,
          event: {"monitor status" => opts[:status]},
          state: opts[:state],
          time: Time.now.utc,
          type: "event",
          event_type: "monitor.#{opts[:type]}"
        }.merge(options)

        pusher.log_event!(event_details)
      end
    end
  end
end
