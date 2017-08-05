require 'spec_base.rb'

module Ragios
  module Plugin
    class GoodPlugin
      attr_reader :test_result
      def init(options); end
      def test_command?; end
    end

    class NoTestCmd
      attr_reader :test_result
      def init(options); end
    end

    class NoTestResult
      def init(options); end
      def test_command?; end
    end

    class NoInit
      attr_reader :test_result
      def test_command?; end
    end

    class Passing
      attr_reader :test_result
      def init(options); end
      def test_command?
        @test_result = {"This test" => "always passes"}
        return true
      end
    end

    class Failing
      attr_reader :test_result
      def init(options); end
      def test_command?
        @test_result = {"This test" => "always fails"}
        return false
      end
    end

    class Error
      attr_reader :test_result
      def init(options); end
      def test_command?
        raise "test_command? error"
      end
    end
  end
end

module Ragios
  module Notifier
    class GoodNotifier
      def init(monitor);end
      def failed(test_result);end
      def resolved(test_result);end
    end

    class OtherGoodNotifier
      def init(monitor);end
      def failed(test_result);end
      def resolved(test_result);end
    end

    class NoInit
      def failed(test_result);end
      def resolved(test_result);end
    end

    class NoFailed
      def init(monitor);end
      def resolved(test_result);end
    end

    class NoResolved
      def init(monitor);end
      def failed(test_result);end
    end
  end
end

describe Ragios::Monitors::GenericMonitor do
  describe "#push_event" do
    it "pushes events to notifier" do
      options = {_id: "monitor_id"}
      generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
      state = "resolved"
      expect(generic_monitor.push_event(state)).to eq({
        monitor_id: "monitor_id",
        state: state,
        event: nil,
        time: nil,
        monitor: options,
        type: "event",
        event_type: "monitor.#{state}"
      })
    end
  end
  describe "State Transitions" do
    context "when monitor state transitions from pending to failed" do
      it "pushes a failed event to Notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "failing",
          via: "good_notifier"
        })
        expect(generic_monitor).to be_pending
        expect(generic_monitor).to receive(:push_event).with("failed")
        generic_monitor.test_command?
        expect(generic_monitor).to be_failed
      end
    end
    context "when monitor state transitions from pending to passed" do
      it "does not push an event to Notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "passing",
          via: "good_notifier"
        })
        expect(generic_monitor).to be_pending
        expect(generic_monitor).not_to receive(:push_event)
        generic_monitor.test_command?
        expect(generic_monitor).to be_passed
      end
    end
    context "when monitor state transitions from pending to error" do
      it "does not push an event to notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "error",
          via: "good_notifier"
        })
        expect(generic_monitor).to be_pending
        expect(generic_monitor).not_to receive(:push_event)
        expect{generic_monitor.test_command?}.to raise_error("test_command? error")
        expect(generic_monitor).to be_error
      end
    end

    context "when monitor state transitions from passed to error" do
      it "does not push an event to notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "error",
          via: "good_notifier"
        })
        generic_monitor.state = "passed"
        expect(generic_monitor).not_to receive(:push_event)
        expect{generic_monitor.test_command?}.to raise_error("test_command? error")
        expect(generic_monitor).to be_error
      end
    end

    context "when monitor state transitions from failed to error" do
      it "does not push an event to notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "error",
          via: "good_notifier"
        })
        generic_monitor.state = "failed"
        expect(generic_monitor).not_to receive(:push_event)
        expect{generic_monitor.test_command?}.to raise_error("test_command? error")
        expect(generic_monitor).to be_error
      end
    end

    context "when monitor state transitions from failed to failed" do
      it "does not push an event to notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "failing",
          via: "good_notifier"
        })
        generic_monitor.state = "failed"
        expect(generic_monitor).not_to receive(:push_event)
        generic_monitor.test_command?
        expect(generic_monitor).to be_failed
      end
    end
    context "when monitor state transitions from passed to passed" do
      it "does not push an event to notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "passing",
          via: "good_notifier"
        })
        generic_monitor.state = "passed"
        expect(generic_monitor).not_to receive(:push_event)
        generic_monitor.test_command?
        expect(generic_monitor).to be_passed
      end
    end
    context "when monitor state transitions from passed to failed" do
      it "pushes a failed event to Notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "failing",
          via: "good_notifier"
        })
        generic_monitor.state = "passed"
        expect(generic_monitor).to receive(:push_event).with("failed")
        generic_monitor.test_command?
        expect(generic_monitor).to be_failed
      end
    end
    context "when monitor state transitions from failed to passed" do
      it "pushes a failed event to Notifier" do
        generic_monitor = Ragios::Monitors::GenericMonitor.new({
          plugin: "passing",
          via: "good_notifier"
        })
        generic_monitor.state = "failed"
        expect(generic_monitor).to receive(:push_event).with("resolved")
        generic_monitor.test_command?
        expect(generic_monitor).to be_passed
      end
    end
  end
  describe "#create_plugin" do
    context "when plugin is included in options" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin implements init(options)" do
            it "creates the plugin" do
              options = {plugin: "good_plugin"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_plugin).to be_a(Ragios::Plugin::GoodPlugin)
              expect(generic_monitor.plugin).to be_a(Ragios::Plugin::GoodPlugin)
            end
          end
        end
      end
    end
    context "when plugin does not implement test_command?" do
      context "when plugin defines test_result" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestCommandNotImplemented exception, plugin not is created" do
              options = {plugin: "no_test_cmd"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestCommandNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not define test_result" do
      context "when plugin implements test_command?" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestResultNotDefined exception, plugin is not created" do
              options = {plugin: "no_test_result"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestResultNotDefined)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not implement init(options) method" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin is included in options" do
            it "raises a PluginInitNotImplemented exception, plugin is not created" do
              options = {plugin: "no_init"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginInitNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when there is no plugin in options" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
    context "when plugin key in options is not a symbol" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {"plugin" => "plugin" }
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
  end

  describe "#create_notifiers" do
    context "when notifiers are not included in options" do
      it "raises a NotifierNotFound exception" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
    context "when notifiers list is empty in options" do
      it "raises a NotifierNotFound exception" do
        options = {via: []}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
    context "when notifier does not implement init" do
      context "when notifier implements failed" do
        context "when notifier implements resolved" do
          it "raises Ragios::NotifierInitNotImplemented error" do
            options = {via: "no_init"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierInitNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier does not implement failed" do
      context "when notifier implements init" do
        context "when notifier implements resolved" do
          it "raises Ragios::NotifierFailedNotImplemented error" do
            options = {via: "no_failed"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierFailedNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier does not implement resolved" do
      context "when notifier implements init" do
        context "when notifier implements failed" do
          it "raises Ragios::NotifierResolvedNotImplemented error, no notifier is created" do
            options = {via: "no_resolved"}
            generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
            expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierResolvedNotImplemented)
            expect(generic_monitor.notifiers).to be_nil
          end
        end
      end
    end
    context "when notifier implements init" do
      context "when notifier implements failed" do
        context "when notifier implements resolved" do
          context "when a single notifier is included in options" do
            it "creates a single notifier" do
              options = {via: "good_notifier"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_notifiers.count).to eq(1)
              expect(generic_monitor.create_notifiers).to include(a_kind_of(Ragios::Notifier::GoodNotifier))
              expect(generic_monitor.notifiers).to include(a_kind_of(Ragios::Notifier::GoodNotifier))
            end
          end
          context "when multiple notifiers are included in options" do
            it "creates multiple notifers" do
              options = {via: ["good_notifier", "other_good_notifier"]}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_notifiers.count).to eq(2)
              expect(generic_monitor.create_notifiers).to include(a_kind_of(Ragios::Notifier::GoodNotifier))
              expect(generic_monitor.notifiers).to include(a_kind_of(Ragios::Notifier::OtherGoodNotifier))
            end
          end
        end
      end
    end
  end
end
