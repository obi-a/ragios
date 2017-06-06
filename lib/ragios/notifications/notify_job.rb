module Ragios
  class NotifyJob
    include Celluloid

    def perform(event, monitor, test_result, notifier)
      begin
        notifier.send(event, test_result) if notifier.respond_to?(event)
        event_details = {
          monitor_id: monitor[:_id],
          state: event,
          time: time.now.utc,
          type: "event",
          event_type: "monitor.notification",
          monitor: monitor,
          test_result: test_result,
          notifier: notifier_name(notifier)
        }
      rescue Exception => exception
        occurred = {"notifier error" => exception.message}
        publisher.async.log_event(
          event_details.merge(event: occurred)
        )
      end
      occurred = {notified: event, via: notifier}
      publisher.async.log_event(
        event_details.merge(event: occurred)
      )
      terminate
    end

  private

    def publisher
      Ragios::EventPublisher.new
    end

    def notifier_name(notifier)
      notifier.class.name.split('::').last.underscore
    end
  end
end
