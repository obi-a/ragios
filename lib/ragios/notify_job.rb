module Ragios
  class NotifyJob
    include SuckerPunch::Job

    def failed(test_result, notifier)
      notifier.failed(test_result) if notifier.respond_to?('failed')
    end

    def resolved(test_result, notifier)
      notifier.resolved(test_result) if notifier.respond_to?('resolved')
    end
  end
end
