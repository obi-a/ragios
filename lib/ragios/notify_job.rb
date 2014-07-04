module Ragios
  class NotifyJob
    include SuckerPunch::Job

    def failed(monitor, test_result, notifier)
      notifier.failed(test_result) if notifier.respond_to?('failed')
      Ragios::Controller.failed(monitor, test_result)
    end
    def resolved(monitor, test_result, notifier)
      notifier.resolved(test_result) if notifier.respond_to?('resolved')
      Ragios::Controller.resolved(monitor, test_result)
    end
  end
end
