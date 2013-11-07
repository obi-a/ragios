require 'spec_base.rb'

module Ragios
  module Notifier
    class TestNotifier 
      attr_reader :notify
      def initialize(monitor)
        @monitor = monitor
        @notify = :nothing
      end
    
      def failed
       @notify = :failed
      end
      def resolved
       @notify = :resolved
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
      def test_command
        @test_result = :test_passed
        return true
      end
    end

    class FailingPlugin < BasePlugin
      attr_reader :test_result
      def test_command
        @test_result = :test_failed
        return false
      end
    end

    class NoTestCommandPlugin < BasePlugin
    end

    class NoTestResultPlugin < BasePlugin
      def test_command
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
   generic_monitor.test_command.should == true
   generic_monitor.test_result.should == :test_passed
   generic_monitor.state.should == "passed"
   notifiers = generic_monitor.notifiers
   notifiers.first.notify.should == :nothing
  end    
end


describe "GenericMonitor transitions" do
  it "should fail test and notify failed, fail again and not notify"
  
  it "should transition from pass to fail and notify failed"
  
  it "should transition from fail to pass and notify resolved, pass again and not notify"
  
  

end
