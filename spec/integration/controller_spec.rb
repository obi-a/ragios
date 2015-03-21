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
  module Plugin
    class ExceptionalPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        raise "something went wrong"
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
        puts "First Notifier FAILED for #{@monitor[:_id]}\n"
      end
      def resolved(test_result)
        puts "First Notifier RESOLVED for #{@monitor[:_id]}\n"
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
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: database_name,
      address: 'http://localhost',
      port: '5984'
    }

    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
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

      [:type, :status_, :created_at_, :creation_timestamp_, :current_state_].each do |e|
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
  describe "#start" do
    it "starts a monitor by id" do
      monitor = {
        monitor: "Something",
        every: "664m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]
      controller.stop(monitor_id)

      controller.start(monitor_id).should == true
      restarted_monitor = @database.get_doc(monitor_id)
      restarted_monitor[:status_].should == "active"
      controller.scheduler.find(monitor_id).first.original.should == "664m"

      #controller.start(monitor_id) is idempotent
      controller.start(monitor_id)
      restarted_monitor = @database.get_doc(monitor_id)
      restarted_monitor[:status_].should == "active"

      controller.delete(monitor_id)
    end

    it "cannot start a monitor that doesn't exist" do
      expect { controller.start("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
  end
  describe "#test_now" do
    it "tests a monitor" do
      failing_monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier",
        plugin: "failing_plugin"
      }

      monitor_id = controller.add(failing_monitor)[:_id]

      #test should fail and display a failed message via mock_notifier
      controller.test_now(monitor_id).should == true

      #verify that the notification event was written to the database
      @database.where(monitor_id: monitor_id, type: "notification", test_result: "test_failed", notifier: "mock_notifier").count == 1

      #verify that the test result was written to the database
      @database.where(monitor_id: monitor_id, type: "test_result", test_result: "test_failed", state: "failed").count == 1

      controller.delete(monitor_id)
    end
    it "tests a monitor with multiple notifiers" do
      failing_monitor = {monitor: "Something",
        every: "5m",
        via: ["first_notifier", "second_notifier"],
        plugin: "failing_plugin"
      }

      monitor_id = controller.add(failing_monitor)[:_id]

      #test should fail and display a failed message via first_notifier and second_notifier
      controller.test_now(monitor_id).should == true

      #verify that both notifiers events are logged to the database
      @database.where(monitor_id: monitor_id, type: "notification", test_result: "test_failed", notifier: "first_notifier").count == 1
      @database.where(monitor_id: monitor_id, type: "notification", test_result: "test_failed", notifier: "second_notifier").count == 1

      #verify that the test result was written to the database
      @database.where(monitor_id: monitor_id, type: "test_result", test_result: "test_failed", state: "failed").count == 1

      controller.delete(monitor_id)
    end
    it "raises an exception when the monitor doesnt exist" do
      expect { controller.test_now("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
    it "rescues exceptions from monitor's test_command, stop the monitor and logs exceptions backtrace" do
      exceptional_monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier",
        plugin: "exceptional_plugin"
      }
      monitor_id = controller.add(exceptional_monitor)[:_id]
      controller.stop(monitor_id)

      controller.test_now(monitor_id)
      sleep 1
      @database.where(monitor_id: monitor_id, type: "event", event_type: "monitor.test", state: "error").count.should_not == 0

      #the monitor is also stopped after an error
      controller.get(monitor_id)[:status_].should == "stopped"

      controller.delete(monitor_id)
    end
  end
  describe "#get" do
    it "returns a monitor by id" do
      monitor = {
        monitor: "Something",
        every: "5m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]

      returned_monitor = controller.get(monitor_id)
      #current_state is not included in the monitor
      returned_monitor[:current_state_].should == nil
      returned_monitor[:_id].should == monitor_id

      #current state is included in monitor
      returned_monitor = controller.get(monitor_id, include_current_state = true)
      returned_monitor[:current_state_].should_not == nil

     controller.delete(monitor_id)
    end

    it "raises an exception if monitor doesn't exist" do
      expect { controller.get("dont_exist") }.to raise_error Ragios::MonitorNotFound
    end
  end
  it "will not start when there is no active monitor" do
    controller.start_all_active.should == nil
  end

  describe "all monitors" do
    before(:each) do
      monitor_1 = {
        monitor: "Something",
        every: "15m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      monitor_2 = {
        monitor: "Something else",
        every: "30m",
        via: "mock_notifier",
        plugin: "passing_plugin"
      }

      @first_monitor = controller.add(monitor_1)[:_id]
      @second_monitor = controller.add(monitor_1)[:_id]
    end
    describe "#start_all_active" do
      it "starts all active monitors" do
        controller.stop(@first_monitor)
        controller.stop(@second_monitor)
        #set stopped monitors as active in database
        #so they can be started by start_all
        status = {status_: "active"}
        @database.edit_doc!(@first_monitor, status)
        @database.edit_doc!(@second_monitor, status)

        controller.start_all_active

        controller.scheduler.find(@first_monitor).first.tags.first.should == @first_monitor
        controller.scheduler.find(@second_monitor).first.tags.first.should == @second_monitor
      end
    end
    after(:each) do
      controller.delete(@first_monitor)
      controller.delete(@second_monitor)
    end
  end
  describe "Log Notifications" do
    it "logs notifications for events failed and resolved" do
      #in this case the previous state is maintained after a monitor update
      monitor = {
        monitor: "Something",
        every: "15m",
        via: "mock_notifier",
        plugin: "failing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]

      sleep 30

      @database.where(type: "event", event_type: "monitor.notification", monitor_id: monitor_id, state: "failed", notifier: "mock_notifier").count.should == 1

      controller.update(monitor_id, plugin: "passing_plugin")

      sleep 30

      @database.where(type: "event", event_type: "monitor.notification", monitor_id: monitor_id, state: "resolved").count.should == 1
      controller.delete(monitor_id)
    end
    it "logs notifications for events failed and resolved monitor restart" do
      monitor = {
        monitor: "Something",
        every: "15m",
        via: "mock_notifier",
        plugin: "failing_plugin"
      }

      monitor_id = controller.add(monitor)[:_id]

      sleep 30

      @database.where(type: "event", event_type: "monitor.notification", monitor_id: monitor_id, state: "failed", notifier: "mock_notifier").count.should == 1

      controller.stop(monitor_id)
      #stopped monitors are not restarted after an update
      controller.update(monitor_id, plugin: "passing_plugin")

      #manually start this monitor
      controller.start(monitor_id)

      sleep 30

      @database.where(type: "event", event_type: "monitor.notification", monitor_id: monitor_id, state: "resolved").count.should == 1

      controller.delete(monitor_id)
    end
  end
  describe "#queries" do
    it "has no errors" do
      expect { controller.get_current_state("dont_exist") }.to_not raise_error
      expect { controller.get_events_by_type("not_found","none", start_date: "2009", end_date: "2001") }.to_not raise_error
      expect { controller.where({}) }.to_not raise_error
      expect { controller.get_events("not_found", start_date: "2009", end_date: "2001") }.to_not raise_error
      expect { controller.get_events_by_state("not_found", "none", start_date: "2009", end_date: "2001") }.to_not raise_error
      expect { controller.get_all }.to_not raise_error
    end
  end
  after(:all) do
    @database.delete
    Ragios::Controller.reset
  end
end
