require 'spec_base.rb'

module Ragios
  module Notifier
    class MockNotifier 
      def initialize(monitor)
        @monitor = monitor
      end
      def failed
        puts "#{monitor.options[:monitor]} FAILED"
      end
      def resolved
        puts "#{monitor.options[:monitor]} RESOLVED"      
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
      def test_command
        @test_result = :test_passed
        return true
      end
    end
  end
end


#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_ruby_api_monitors',
                               activity_log: 'test_ruby_api_activity_log',
                               auth_session: 'test_ruby_api_auth_session'},
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


describe "Ragios" do
  before(:all) do
    Ragios::CouchdbAdmin.create_database
  end
  
  it "adds a monitor" do
  
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }     
    
    generic_monitors = controller.add([monitor])
    generic_monitor = generic_monitors.first
    generic_monitor.is_a?(Ragios::GenericMonitor).should == true
    generic_monitor.options.should include(monitor)
    generic_monitor.state.should == "passed"
    generic_monitor.passed?.should == true
    controller.delete(generic_monitor.id)
  end
  
  it "cannot add a monitor with no plugin" do
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier"} 
    
    expect { controller.add([monitor]) }.to raise_error Ragios::PluginNotFound   
  end
  
  it "cannot add a monitor with no notifier" do
    monitor = {monitor: "Something",
      every: "5m",
      plugin: "passing_plugin" }  
    
    expect { controller.add([monitor]) }.to raise_error Ragios::NotifierNotFound     
  end 
  
  it "updates a monitor" do
    #setup
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }     
    
    monitor_id = controller.add([monitor]).first.id
    update_data = {every: "1h", monitor: "New name"}
    
    updated_monitor = controller.update(monitor_id,update_data).first
    
    updated_monitor.id.should == monitor_id
    updated_monitor.options.should include(update_data)
    controller.delete(monitor_id)   
  end
  
  it "cannot update a monitor that doesn't exist" do 
    update_data = {every: "1h", monitor: "New name"}  
    expect { controller.update("dont_exist",update_data) }.to raise_error Ragios::MonitorNotFound  
  end
  
  it "stops a running monitor" do
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }  
    generic_monitor = controller.add([monitor]).first 
    
    hash =  controller.stop(generic_monitor.id)
    hash.should include("id" => generic_monitor.id, "ok" => true) 

    #controller.stop is idempotent 
    hash =  controller.stop(generic_monitor.id)       
    hash.should include("id" => generic_monitor.id, "ok" => true)
  end
  
  it "cannot stop a monitor that doesn't exist" do
    expect { controller.stop("dont_exist") }.to raise_error Ragios::MonitorNotFound
  end
  
  it "deletes a monitor" do
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }   
    generic_monitor = controller.add([monitor]).first 
    controller.delete(generic_monitor.id)   
    expect { controller.get(generic_monitor.id) }.to raise_error Ragios::MonitorNotFound
  end
  
  it "cannot delete a monitor that doesn't exist"
  
  after(:all) do
    Couchdb.delete database, auth_session
  end
end
