module Ragios
  module Notifications
    class NotificationWorker
      include Celluloid

      def perform(options)
        notification_event =  JSON.parse(options, symbolize_names: true)
        generic_notifier = Notifications::GenericMonitor.new(notification_event)
        generic_notifier.notify
      end
    end
  end
end
