module Ragios
  module Notifications
    class GenericMonitor < Ragios::Monitors::GenericMonitor

      def initialize(notification_event)
        @options = notification_event.fetch(:monitor)
        @id = notification_event.fetch(:monitor_id)
        @time_of_test = notification_event.fetch(:time)
        @test_result = notification_event.fetch(:event)
        create_notifiers
        @state = notification_event.fetch(:state)
        @worker_pool = Notifications::NotifyWorker.pool(size: 20)
      end

      def notify
        @notifiers.each do |notifier|
          @worker_pool.async.perform(@state, @options, @test_result, notifier)
        end
      end
    end
  end
end
