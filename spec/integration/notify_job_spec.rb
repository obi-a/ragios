require 'spec_base.rb'

module Ragios
  module Notifier
    class TestNotifyJobNotifier
      def failed(test_result)
      end
      def resolved(test_result)
      end
    end
 end
end

module Ragios
  module Notifier
    class ErrorNotifier
      def failed(test_result)
        raise "notifier error inside failed"
      end
      def resolved(test_result)
        raise "notifier error inside resolved"
      end
    end
  end
end

describe "Ragios::NotifyJob" do
  before(:all) do
    #database configuration
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: 'ragios_test_notify_job_database',
      address: 'http://localhost',
      port: '5984'
    }

    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
    @database = Ragios::CouchdbAdmin.get_database
  end

  describe "#failed and #resolved" do
    it "sends a notification during a failure or resolved event" do
      monitor = {
        _id: "test_notify_job_id",
        monitor: "test_notify_job",
        via: "test_notify_job_notifier"
      }

      test_result = {"testing" => "notify job"}
      notifier = Ragios::Notifier::TestNotifyJobNotifier.new

      notify_job = Ragios::NotifyJob.new
      notify_job.failed(monitor, test_result, notifier)
      notify_job.resolved(monitor, test_result, notifier)
      #sleep 1

      #assert that events are logged correctly
      @database.where(
        type: "event",
        event_type: "monitor.notification",
        monitor_id: monitor[:_id],
        state: "failed",
        notifier: "test_notify_job_notifier"
      ).count.should == 1

      @database.where(
        type: "event",
        event_type: "monitor.notification",
        monitor_id: monitor[:_id],
        state: "resolved",
        notifier: "test_notify_job_notifier"
      ).count.should == 1
    end
    it "handles exceptions and errors from notifiers" do
      monitor = {
        _id: "error_monitor_id",
        monitor: "test_notify_job",
        via: "error_notifier"
      }

      test_result = {"testing" => "notify job"}
      notifier = Ragios::Notifier::ErrorNotifier.new

      notify_job = Ragios::NotifyJob.new

      notify_job.failed(monitor, test_result, notifier)
      notify_job.resolved(monitor, test_result, notifier)

      #sleep 1

      #assert that the error events are logged correctly
      @database.where(
        type: "event",
        event_type: "monitor.notification",
        monitor_id: monitor[:_id],
        state: "failed",
        notifier: "error_notifier"
      ).count.should == 1

      @database.where(
        type: "event",
        event_type: "monitor.notification",
        monitor_id: monitor[:_id],
        state: "resolved",
        notifier: "error_notifier"
      ).count.should == 1
    end
  end
  after(:all) do
    @database.delete
    Ragios::Controller.reset
  end
end