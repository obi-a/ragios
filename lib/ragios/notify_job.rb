module Ragios
  class NotifyJob
    include SuckerPunch::Job

    def failed(monitor, notifier)
      notifier.failed(monitor) if notifier.respond_to?('failed')
    end

    def resolved(monitor, notifier)
      notifier.resolved(monitor) if notifier.respond_to?('resolved')
    end
  end
end
