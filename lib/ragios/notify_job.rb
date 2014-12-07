module Ragios
  class NotifyJob
    include SuckerPunch::Job
    #add unit tests for this class and handle notifier exceptions
    #TODO: when notifier.failed/resolved fails the notifyJob crashes
    #controller should log that the notifier crashed
    def failed(monitor, test_result, notifier)
      notifier.failed(test_result) if notifier.respond_to?('failed')
      Ragios::Controller.failed(monitor, test_result, notifier_name(notifier))
    end
    def resolved(monitor, test_result, notifier)
      notifier.resolved(test_result) if notifier.respond_to?('resolved')
      Ragios::Controller.resolved(monitor, test_result, notifier_name(notifier))
    end
  private
    def notifier_name(notifier)
      notifier.class.name.split('::').last.underscore
    end
  end
end
