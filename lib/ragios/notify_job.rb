module Ragios
  class NotifyJob
    include SuckerPunch::Job

    def failed(notifier)
      notifier.failed if notifier.respond_to?('failed')    
    end
  
    def resolved(notifier)
      notifier.resolved if notifier.respond_to?('resolved')   
    end
  end
end
