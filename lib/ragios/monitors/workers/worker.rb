module Ragios
  module Monitors
    module Workers
      class Worker
        include Celluloid

        def perform(monitor_id)
          generic_monitor =  Ragios::Monitors::GenericMonitor.find(monitor_id)
          generic_monitor.test_command?
          results = {
            monitor_id: generic_monitor.id,
            state: generic_monitor.state,
            event: generic_monitor.test_result,
            time: generic_monitor.time_of_test,
            monitor: generic_monitor.options,
            type: "event",
            event_type: "monitor.test"
          }
          publisher.async.log_event!(results)
          Ragios.logger.info "#{self.class.name} performed test for monitor_id #{generic_monitor.id}, state: #{generic_monitor.state}, result: #{generic_monitor.test_result}, complete state: #{results}"
        rescue Exception => e
          log_error(e, generic_monitor)
          raise e
        end

      private
        def log_error(exception, generic_monitor)
          publisher.async.log_event!(
            monitor_id: generic_monitor&.id,
            state: "error",
            event: {error: exception.message},
            time: generic_monitor&.time_of_test,
            monitor: generic_monitor&.options,
            type: "event",
            event_type: "monitor.test"
          )
        end

        def publisher
          Ragios::Events::Publisher.new
        end
      end
    end
  end
end
