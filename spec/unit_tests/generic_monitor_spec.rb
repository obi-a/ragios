require 'spec_base.rb'

module Ragios
  module Notifier
    class TestNotifier
      def initialize(monitor)
      end
      def failed(test_result)
      end
      def resolved(test_result)
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

module Ragios
  class Controller
    def self.failed(*args)
    end
  end
end


describe Ragios::GenericMonitor do
  before(:all) do
    #database configuration
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: 'ragios_test_generic_monitor_database',
      address: 'http://localhost',
      port: '5984'
    }
    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
  end

  it "should pass the test" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      via: "test_notifier",
      plugin: "passing_plugin"
    }
    generic_monitor = Ragios::GenericMonitor.new(options)
    generic_monitor.test_command?.should == true
    generic_monitor.test_result.should == :test_passed
    generic_monitor.state.should == "passed"
    generic_monitor.passed?.should == true
  end

  it "should fail the test" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      via: "test_notifier",
      plugin: "failing_plugin"
    }
    generic_monitor = Ragios::GenericMonitor.new(options)
    generic_monitor.test_command?.should == false
    generic_monitor.test_result.should == :test_failed
    generic_monitor.state.should == "failed"
    generic_monitor.failed?.should == true
  end

  it "should throw exception if no plugin.test_command? defined" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      via: "test_notifier",
      plugin: "no_test_command_plugin"
    }
    generic_monitor = Ragios::GenericMonitor.new(options)
    expect { generic_monitor.test_command? }.to raise_error(Ragios::PluginTestCommandNotFound)
  end

  it "should throw exception if no plugin.test_result" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      via: "test_notifier",
      plugin: "no_test_result_plugin"
    }
    generic_monitor = Ragios::GenericMonitor.new(options)
    expect { generic_monitor.test_command? }.to raise_error(Ragios::PluginTestResultNotFound)
  end

  it "cannot create a monitor with no notifier" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      plugin: "passing_plugin"
    }
    expect { Ragios::GenericMonitor.new(options) }.to raise_error(Ragios::NotifierNotFound)
  end

  it "cannot create a monitor with no plugin" do
    options = {
      monitor: "something",
      _id: "monitor_id",
      via: "test_notifier"
    }
    expect { Ragios::GenericMonitor.new(options) }.to raise_error(Ragios::PluginNotFound)
  end
  after(:all) do
    Ragios::CouchdbAdmin.get_database.delete
  end
end
