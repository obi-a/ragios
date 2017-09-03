module Ragios
  module Notifications
    class NotificationWorker
      include Celluloid

      def perform(options)
        notification_event =  JSON.parse(options, symbolize_names: true)
        generic_monitor = Notifications::GenericMonitor.new(notification_event)
        generic_monitor.notify
      end
    end
  end
end
