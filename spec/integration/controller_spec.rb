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

      controller.delete(created_monitor[:_id])
    end
    it "raises an exception when monitor has no plugin" do
      monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier"
      }
      expect { controller.add(monitor) }.to raise_error Ragios::PluginNotFound
    end
    it "raises an exception when monitor with no notifier" do
      monitor = {
        monitor: "Something",
        every: "5m",
        plugin: "passing_plugin"
      }
      expect { controller.add(monitor) }.to raise_error Ragios::NotifierNotFound
    end
  end
  describe "#update" do
    it "updates a running monitor" do
      #setup
      old_time = "5m"
      monitor = {
        monitor: "Something",
        every: old_time,
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]
      #setup ends

      #time set in the scheduler before update
      controller.scheduler.find(monitor_id).first.original.should == old_time
      new_time = "1h"
      update_data = {every: new_time, monitor: "New name"}

      controller.update(monitor_id, update_data)
      @database.get_doc(monitor_id).should include(update_data)

      #scheduler restarted after update with new time
      controller.scheduler.find(monitor_id).first.original.should == new_time

      #tear down
      controller.delete(monitor_id)
    end
    it "updates a stopped monitor" do
      #setup
      old_time = "5m"
      monitor = {
        monitor: "Something",
        every: old_time,
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]
      controller.stop(monitor_id)
      #setup ends

      #monitor is not in scheduler before update
      controller.scheduler.find(monitor_id).should == []
      new_time = "1h"
      update_data = {every: new_time, monitor: "New name"}

      controller.update(monitor_id, update_data)
      @database.get_doc(monitor_id).should include(update_data)

      #monitor is still not in scheduler and scheduler is not restarted
      controller.scheduler.find(monitor_id).should == []

      #tear down
      controller.delete(monitor_id)
    end
    it "cannot update a monitor that doesn't exist, it raises an exception" do
      update_data = {every: "1h", monitor: "New name"}
      expect { controller.update("dont_exist",update_data) }.to raise_error Ragios::MonitorNotFound
    end
    it "cannot update a system status, it raises an exception" do
      #setup
      monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]
      #setup ends

      [:type, :status_, :created_at_, :creation_timestamp_].each do |e|
        update_data = {every: "1h", monitor: "New name", e => "something"}
        expect { controller.update(monitor_id, update_data) }.to raise_error Ragios::CannotEditSystemSettings
      end

      #tear down
      controller.delete(monitor_id)
    end
  end
  describe "#stop" do
    it "stops a running monitor" do
      monitor = {
        monitor: "Something",
        every: "77m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }
      monitor_id = controller.add(monitor)[:_id]
      controller.scheduler.find(monitor_id).first.original.should == "77m"

      controller.stop(monitor_id).should ==  true
      monitor = @database.get_doc(monitor_id)
      monitor[:status_].should == "stopped"

      controller.scheduler.find(monitor_id).should == []

      #controller.stop is idempotent
      controller.stop(monitor_id).should ==  true
      monitor = @database.get_doc(monitor_id)
      monitor[:status_].should == "stopped"

      controller.delete(monitor_id)
    end

    it "cannot stop a monitor that doesn't exist" do
      expect { controller.stop("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
  end
  describe "#delete" do
    it "deletes a running monitor" do
      monitor = {
        monitor: "Something",
        every: "88m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }
      monitor_id = controller.add(monitor)[:_id]
      controller.scheduler.find(monitor_id).first.original.should == "88m"

      controller.delete(monitor_id).should == true
      #the monitor gets deleted from the database
      expect { @database.get_doc(monitor_id) }.to raise_error Leanback::CouchdbException
      #the monitor gets removed from scheduler
      controller.scheduler.find(monitor_id).should == []
    end

    it "cannot delete a monitor that doesn't exist" do
      expect { controller.delete("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
  end
  describe "#restart" do
    it "restarts a monitor by id" do
      monitor = {
        monitor: "Something",
        every: "664m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]
      controller.stop(monitor_id)

      controller.restart(monitor_id).should == true
      restarted_monitor = @database.get_doc(monitor_id)
      restarted_monitor[:status_].should == "active"
      controller.scheduler.find(monitor_id).first.original.should == "664m"

      #controller.restart(monitor_id) is idempotent
      controller.restart(monitor_id)
      restarted_monitor = @database.get_doc(monitor_id)
      restarted_monitor[:status_].should == "active"

      controller.delete(monitor_id)
    end

    it "cannot restart a monitor that doesn't exist" do
      expect { controller.restart("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
  end
  after(:all) do
    @database.delete
  end
end
