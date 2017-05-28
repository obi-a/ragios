module Ragios
  class NotifyJob
    #include SuckerPunch::Job

    def failed(monitor, test_result, notifier)
      handle_event(:failed, monitor, test_result, notifier)
    end

    def resolved(monitor, test_result, notifier)
      handle_event(:resolved, monitor, test_result, notifier)
    end

  private

    def handle_event(event, monitor, test_result, notifier)
      begin
        notifier.send(event, test_result) if notifier.respond_to?(event)
      rescue Exception => e
        Ragios::Controller.notifier_failure(notifier_name(notifier), e, event, monitor, test_result)
        return false
      end
      Ragios::Controller.send(event, monitor, test_result, notifier_name(notifier))
    end

    def notifier_name(notifier)
      notifier.class.name.split('::').last.underscore
    end
  end
end
