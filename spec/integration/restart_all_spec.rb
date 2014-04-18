require 'spec_base.rb'
require 'spec_base.rb'

module Ragios
  module Notifier
    class MockNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed(test_result)
        puts "#{@monitor.options[:_id]} FAILED"
      end
      def resolved(test_result)
        puts "#{@monitor.options[:_id]} RESOLVED"
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

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_restart_all',
                               activity_log: 'test_restart_all',
                               auth_session: 'test_restart_all'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 }

Ragios::CouchdbAdmin.config(database_admin)
database = Ragios::CouchdbAdmin.monitors
auth_session = Ragios::CouchdbAdmin.session


controller = Ragios::Controller
scheduler = Ragios::Scheduler.new(controller)
model = Ragios::Model::CouchdbMonitorModel
logger = Ragios::CouchdbLogger.new
controller.scheduler(scheduler)
controller.model(model)
controller.logger(logger)



describe "Restart All" do
  before(:all) do
    Ragios::CouchdbAdmin.create_database
  end

  it "restarts all monitors from database" do
    #setup starts
    monitors = [{monitor: "Something",
                every: "5m",
                via: "mock_notifier",
                plugin: "passing_plugin" },
               {monitor: "Something else",
                every: "30m",
                via: "mock_notifier",
                plugin: "passing_plugin"}]

    generic_monitors = controller.add(monitors)
    first_monitor = generic_monitors.first.id
    second_monitor = generic_monitors[1].id
    #stop monitors
    controller.stop(first_monitor)
    controller.stop(second_monitor)
    #set stopped monitors as active in database
    #so they can be restarted by restart_all
    status = {:status_ => "active"}
    model.update(first_monitor,status)
    model.update(second_monitor,status)
    #setup ends

    restarted_monitors = controller.restart_all
    restarted_monitors.length.should == 2
    [restarted_monitors[0].id, restarted_monitors[1].id].should include(first_monitor,second_monitor)
  end

  after(:all) do
    Couchdb.delete database, auth_session
  end
end
