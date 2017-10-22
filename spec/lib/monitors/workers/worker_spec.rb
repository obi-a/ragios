require 'spec_base.rb'

module Ragios
  module Notifiers
    class GoodNotifier
      def init(monitor);end
      def failed(test_result);end
      def resolved(test_result);end
    end
  end
end

module Ragios
  module Plugins
    class GoodPlugin
      attr_reader :test_result
      def init(options); end
      def test_command?
        @test_result = {test: "success"}
        true
      end
    end

    class ExceptionalPlugin
      attr_reader :test_result
      def init(options); end
      def test_command?
        raise "Something went wrong"
      end
    end
  end
end

describe Ragios::Monitors::Workers::Worker do
  before(:each) do
    Celluloid.shutdown; Celluloid.boot
    @monitor_id = SecureRandom.uuid
    time  = Time.now
    database = Ragios.database

    monitor = {
      monitor: "sample test",
      every:  "10m",
      type: "monitor",
      status_: "active",
      via: [:good_notifier],
      plugin: "good_plugin"
    }

    database.create_doc(@monitor_id, monitor)

    exceptional_monitor = {
      monitor: "sample test",
      every:  "10m",
      type: "monitor",
      status_: "active",
      via: [:good_notifier],
      plugin: "exceptional_plugin"
    }
    @exceptional_monitor_id = SecureRandom.uuid
    database.create_doc(@exceptional_monitor_id, exceptional_monitor)

    @worker = Ragios::Monitors::Workers::Worker.new
  end
  context "when provided an existing monitor_id" do
    context "when it performs the monitors test_command?" do
      it "publishes the test results" do
        subscriber = Ragios::Events::Subscriber.new
        future = subscriber.future.receive
        @worker.perform(@monitor_id)
        result = JSON.parse(future.value, symbolize_names: true)
        expect(result).to include(monitor_id: @monitor_id, state: "passed", event: {test: "success"})
      end
      context "when test command raises an exception" do
        it "handles the error and publishes the error" do
          subscriber = Ragios::Events::Subscriber.new
          future = subscriber.future.receive
          expect{ @worker.perform(@exceptional_monitor_id) }.to raise_error(/Something went wrong/)
          result = JSON.parse(future.value, symbolize_names: true)
          expect(result).to include(monitor_id: @exceptional_monitor_id, event_type: "monitor.error", event: {error: "Something went wrong"})
        end
      end
    end
  end
  context "when provided monitor id is not found" do
    it "handles the error and publishes the error" do
      subscriber = Ragios::Events::Subscriber.new
      future = subscriber.future.receive
      expect{ @worker.perform("not_found") }.to raise_error(Ragios::MonitorNotFound)
      result = JSON.parse(future.value, symbolize_names: true)
      expect(result).to include(monitor_id: nil, event_type: "monitor.error", event: {error: "No monitor found with id = not_found"})
    end
  end
end
