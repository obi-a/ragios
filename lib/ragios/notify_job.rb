module Ragios
  class NotifyJob
    include SuckerPunch::Job

    def failed(test_result, notifier)
      notifier.failed(test_result) if notifier.respond_to?('failed')
      #write notification to database
      Ragios::Controller.failed(test_result)
    end

    def resolved(test_result, notifier)
      notifier.resolved(test_result) if notifier.respond_to?('resolved')
      #write notification to database
      Ragios::Controller.resolved(test_result)
    end
  end
end
