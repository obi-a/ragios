module Ragios
  module Monitors
    module Workers
      class Worker
        include Celluloid

        def perform(monitor_id)
          puts "got this id #{monitor_id}"
          generic_monitor =  Ragios::Monitors::Loader.new(monitor_id).generic_monitor
          generic_monitor.test_command?
          publisher.async.log_event!(
            monitor_id: generic_monitor.id,
            state: generic_monitor.state,
            event: generic_monitor.test_result,
            time: generic_monitor.time_of_test,
            monitor: generic_monitor.options,
            type: "event",
            event_type: "monitor.test"
          )
        rescue Exception => e
          log_error(e, generic_monitor)
          raise e
        end

      private
        def log_error(exception, generic_monitor)
          publisher.async.log_event!(
            monitor_id: generic_monitor.id,
            state: "error",
            event: {error: exception.message},
            time: generic_monitor.time_of_test,
            monitor: generic_monitor.options,
            type: "event",
            event_type: "monitor.test"
          )
        end

        def publisher
          Ragios::EventPublisher.new
        end
      end
    end
  end
end
