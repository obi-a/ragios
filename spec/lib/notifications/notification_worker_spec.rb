require 'spec_base.rb'

module Ragios
  module Notifiers
    class GoodNotifier
      def init(monitor);end
      def failed(test_result)
        Ragios.logger.info("#{self.class.name} notifying failed")
      end
      def resolved(test_result);end
    end

    class ExceptionalNotifier
      def init(monitor);end
      def failed(test_result)
        raise "something went wrong"
      end
      def resolved(test_result);end
    end
  end
end

describe Ragios::Notifications::NotificationWorker do
  before(:each) do
    Celluloid.shutdown; Celluloid.boot
    @monitor_id = SecureRandom.uuid
    time  = Time.now
    @monitor_with_exceptional_notifier =  {
      _id: @monitor_id,
      _rev: "128-f52feb01bf8e111124844e2d6ed78f64",
      monitor: "sample test",
      every:  "10m",
      type: "monitor",
      status_: "active",
      via: [:exceptional_notifier],
      created_at_: time
    }
    @notification_event =  {
      monitor_id: @monitor_id,
      state: "failed",
      event: {:"This test"=>"does nothing"},
      time: "2017-09-02T00:40:18Z",
      monitor:
      {
        _id: @monitor_id,
        _rev: "128-f52feb01bf8e111124844e2d6ed78f64",
        monitor: "sample test",
        every:  "10m",
        type: "monitor",
        status_: "active",
        via: [:good_notifier],
        created_at_: time
      },
      :type=>"event",
      :event_type=>"monitor.failed"
    }
    @worker = Ragios::Notifications::NotificationWorker.new
  end
  context "when provided a valid notification event" do
    it "sends the correct notification" do
      subscriber = Ragios::Events::Subscriber.new
      future = subscriber.future.receive
      @worker.perform(JSON.generate(@notification_event))
      result = JSON.parse(future.value, symbolize_names: true)
      expect(result).to include(event: {notified: "failed", via: "GoodNotifier"}, monitor_id: @monitor_id, event_type: "monitor.notification")
    end
    it "handles notifier errors" do
      subscriber = Ragios::Events::Subscriber.new
      future = subscriber.future.receive
      @notification_event[:monitor] = @monitor_with_exceptional_notifier
      @worker.perform(JSON.generate(@notification_event))
      result = JSON.parse(future.value)
      expect(result["event"]).to eq("notifier error" => "something went wrong")
    end
  end
end