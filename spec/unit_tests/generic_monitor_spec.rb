require 'spec_base.rb'

module Ragios
  module Notifier
    class TestNotifier
      def initialize(monitor)
      end
      def failed
      end
      def resolved
      end
    end
 end
end

module Ragios
  module Plugin
    class BasePlugin
      def init(options)
      end
    end

    class PassingPlugin < BasePlugin
      attr_reader :test_result
      def test_command?
        @test_result = :test_passed
        return true
      end
    end

    class FailingPlugin < BasePlugin
      attr_reader :test_result
      def test_command?
        @test_result = :test_failed
        return false
      end
    end

    class NoTestCommandPlugin < BasePlugin
    end

    class NoTestResultPlugin < BasePlugin
      def test_command?
        return false
      end
    end
  end
end

describe Ragios::GenericMonitor do

  it "should pass the test" do
    options = {monitor: "something",
               _id: "monitor_id",
               via: "test_notifier",
               plugin: "passing_plugin" }
   generic_monitor = Ragios::GenericMonitor.new(options)
   generic_monitor.test_command?.should == true
   generic_monitor.test_result.should == :test_passed
   generic_monitor.state.should == "passed"
   generic_monitor.passed?.should == true
  end

  it "should fail the test" do
    options = {monitor: "something",
               _id: "monitor_id",
               via: "test_notifier",
               plugin: "failing_plugin" }
    generic_monitor = Ragios::GenericMonitor.new(options)
    generic_monitor.test_command?.should == false
    generic_monitor.test_result.should == :test_failed
    generic_monitor.state.should == "failed"
    generic_monitor.failed?.should == true
  end

  it "should throw exception if no plugin.test_command? defined" do
    options = {monitor: "something",
               _id: "monitor_id",
               via: "test_notifier",
               plugin: "no_test_command_plugin" }
    generic_monitor = Ragios::GenericMonitor.new(options)
    expect { generic_monitor.test_command? }.to raise_error(Ragios::PluginTestCommandNotFound)
  end

  it "should throw exception if no plugin.test_result" do
    options = {monitor: "something",
               _id: "monitor_id",
               via: "test_notifier",
               plugin: "no_test_result_plugin" }
    generic_monitor = Ragios::GenericMonitor.new(options)
    expect { generic_monitor.test_command? }.to raise_error(Ragios::PluginTestResultNotFound)
  end

  it "cannot create a monitor with no notifier" do
    options = {monitor: "something",
               _id: "monitor_id",
               plugin: "passing_plugin" }
    expect { Ragios::GenericMonitor.new(options) }.to raise_error(Ragios::NotifierNotFound)
  end

  it "cannot create a monitor with no plugin" do
    options = {monitor: "something",
               _id: "monitor_id",
               via: "test_notifier"}
    expect { Ragios::GenericMonitor.new(options) }.to raise_error(Ragios::PluginNotFound)
  end
  describe "failure tolerance" do
    it "does not notify until fails exceed fail_tolerance" do
      options = {monitor: "something",
                  _id: "monitor_id",
                  fail_tolerance: 4,
                  via: "test_notifier",
                  plugin: "failing_plugin"
                }
      generic_monitor = Ragios::GenericMonitor.new(options)
      count = 0
      loop do
        count += 1
        generic_monitor.test_command?
        generic_monitor.failure_notified.should == false
        generic_monitor.failures.should == count
        break if count == 4
      end
      #after 4 fails send  a notification
      generic_monitor.test_command?
      generic_monitor.failure_notified.should == true
      generic_monitor.failures.should > options[:fail_tolerance]
      #don't send a notification since you have already notifed user
      generic_monitor.test_command?
      generic_monitor.failure_notified.should == true
      #failure_notified and failures are reset after test passes and again
      generic_monitor.fire_state_event(:success)
      generic_monitor.failure_notified.should == false
      generic_monitor.failures.should == 0
    end
  end
  describe "initial states" do
    it "should set state passed" do
      options = {monitor: "something",
                 _id: "monitor_id",
                 via: "test_notifier",
                 state_: "passed",
                 plugin: "failing_plugin" }
      generic_monitor = Ragios::GenericMonitor.new(options)
      generic_monitor.passed?.should == true
    end

    it "should set state failed" do
      options = {monitor: "something",
                 _id: "monitor_id",
                 via: "test_notifier",
                 state_: "failed",
                 plugin: "passing_plugin" }
      generic_monitor = Ragios::GenericMonitor.new(options)
      generic_monitor.failed?.should == true
    end

    it "should set state pending" do
      options = {monitor: "something",
                 _id: "monitor_id",
                 via: "test_notifier",
                 plugin: "passing_plugin" }
      generic_monitor = Ragios::GenericMonitor.new(options)
      generic_monitor.pending?.should == true
    end
  end
end
