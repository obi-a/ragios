require 'spec_base.rb'

module Ragios
  module Notifier
    class MockNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed(test_result)
        puts "#{@monitor[:_id]} FAILED"
      end
      def resolved(test_result)
        puts "#{@monitor[:_id]} RESOLVED"
      end
    end
  end
end

module Ragios
  module Plugin
    class PassingPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        @test_result = :test_passed
        return true
      end
    end
  end
end

module Ragios
  module Plugin
    class FailingPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        @test_result = :test_failed
        return false
      end
    end
  end
end

module Ragios
  module Notifier
    class FirstNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed(test_result)
        puts "First Notifier FAILED for #{@monitor[:_id]}"
      end
      def resolved(test_result)
        puts "First Notifier RESOLVED for #{@monitor[:_id]}"
      end
    end
  end
end

module Ragios
  module Notifier
    class SecondNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed(test_result)
        puts "Second Notifier FAILED for #{@monitor[:_id]}"
      end
      def resolved(test_result)
        puts "Second Notifier RESOLVED for #{@monitor[:_id]}"
      end
    end
  end
end

controller = Ragios::Controller

describe Ragios::Controller do
  before(:all) do
    database_name = "test_ragios_controller_#{Time.now.to_i}"
    database_admin = {login: {username: ENV['COUCHDB_ADMIN_USERNAME'], password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                        database: database_name,
                        couchdb:  {address: 'http://localhost', port:'5984'}
                     }

    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database.should == true
    @database = Ragios::CouchdbAdmin.get_database
  end

  describe "#add" do
    it "creates and starts a new monitor" do
      monitor = {
        monitor: "Something",
        every: "5m",
        via: ["mock_notifier"],
        plugin: "passing_plugin"
      }

      created_monitor = controller.add(monitor)
      created_monitor.should include(monitor)
      created_monitor[:status_].should == "active"
      @database.delete_doc!(created_monitor[:_id])
    end
    it "raises an exception when monitor has no plugin" do
      monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier"
      }
      expect { controller.add(monitor) }.to raise_error Ragios::PluginNotFound
    end
    it "cannot add a monitor with no notifier" do
      monitor = {
        monitor: "Something",
        every: "5m",
        plugin: "passing_plugin"
      }
      expect { controller.add(monitor) }.to raise_error Ragios::NotifierNotFound
    end
  end

  after(:all) do
    @database.delete
  end
end