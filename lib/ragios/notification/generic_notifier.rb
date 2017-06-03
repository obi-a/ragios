module Ragios
  class GenericNotifier < Ragios::GenericMonitor

    def initialize(notification_event)
      @options = nofitcation_event[:monitor]
      @id = @options[:monitor_id]
      @time_of_test = notification_event[:time]
      @test_result = notification_event[:event]
      create_notifiers
      @state = notification_event[:state]
    end

    def notify
      @notifiers.each do |notifier|
        NotifyJob.new.async.send(@state, @options, @test_result, notifier)
      end
    end
  end
end
