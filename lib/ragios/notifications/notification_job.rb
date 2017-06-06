module Ragios
  class NotificationJob
    include Celluloid

    def perform(options)
      notification_event =  JSON.parse(options, symbolize_names: true)
      generic_notifier = Ragios::GenericNotifier.new(notification_event)
      generic_notifier.notify
    end
  end
end
