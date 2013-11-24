require 'spec_base.rb'

module Ragios
  module Notifier
    class MockNotifier 
      def initialize(monitor)
        @monitor = monitor
      end
      def failed
        puts "#{@monitor.options[:_id]} FAILED"
      end
      def resolved
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
      def test_command
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
      def test_command
        @test_result = :test_failed
        return false
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
    #setup ends
    
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
    monitor_id = generic_monitor.id
    
    hash =  controller.stop(monitor_id)
    hash.should include("id" => monitor_id, "ok" => true) 
    monitor = controller.get(monitor_id)
    monitor[:status_].should == "stopped"

    #controller.stop is idempotent 
    hash =  controller.stop(monitor_id)       
    hash.should include("id" => monitor_id, "ok" => true)
       
    controller.delete(monitor_id)
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
    monitor_id = generic_monitor.id
    
    controller.delete(monitor_id)   
    expect { controller.get(monitor_id) }.to raise_error Ragios::MonitorNotFound
  end
  
  it "cannot delete a monitor that doesn't exist" do
    expect { controller.delete("dont_exist") }.to raise_error Ragios::MonitorNotFound 
  end
  
  it "restarts a monitor by id" do
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }  
    generic_monitor = controller.add([monitor]).first 
    controller.stop(generic_monitor.id) 
    monitor_id = generic_monitor.id
    monitor = controller.get(monitor_id)
    monitor[:status_].should == "stopped"    
    
    controller.restart(monitor_id)  
    monitor = controller.get(monitor_id)
    monitor[:status_].should == "active"
    
    #controller.restart(monitor_id) is idempotent 
    controller.restart(monitor_id)  
    monitor = controller.get(monitor_id)
    monitor[:status_].should == "active"  
    
    controller.delete(monitor_id)  
  end
  
  it "cannot restart a monitor that doesn't exist" do
    expect { controller.restart("dont_exist") }.to raise_error Ragios::MonitorNotFound 
  end
  
 it "tests a monitor" do
    failing_monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "failing_plugin" }     
    
    monitor_id = controller.add([failing_monitor]).first.id
    
    #test should fail and display a failed message via mock_notifier
    controller.test_now(monitor_id) 
    
    #controller.update automatically restarts and tests monitor
    #test should pass this time and displays a resolved via mock_notifier
    controller.update(monitor_id, plugin: "passing_plugin")
    controller.delete(monitor_id)      
 end
 
 it "returns a monitor by id" do
   monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }     
    
   monitor_id = controller.add([monitor]).first.id   
    
   returned_monitor = controller.get(monitor_id)
   returned_monitor[:_id].should == monitor_id
   controller.delete(monitor_id) 
 end
 
 it "cannot return a monitor that doesn't exist" do
    expect { controller.get("dont_exist") }.to raise_error Ragios::MonitorNotFound 
 end
 
 it "finds monitors by multiple keys" do
   unique_name = "Something unique #{Time.now.to_i}"
   monitor = {monitor: unique_name,
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin" }     
    
    monitor_id = controller.add([monitor]).first.id 
   
    results = controller.find_by(monitor: unique_name, every: "5m")
    results.first[:_id].should == monitor_id
  end
 
  it "cannot find a monitor that doesn't exist by multiple keys" do 
    unique_name = "Something unique #{Time.now.to_i}"
    controller.find_by(monitor: unique_name, tag: "xyz").should == []
  end
  
  it "runs a monitor without database persistence or logging" do
    monitor = {monitor: "Something",
      every: "5m",
      via: "mock_notifier",
      plugin: "passing_plugin"}     
    
    generic_monitor = controller.run([monitor]).first  
    monitor_id = generic_monitor.id
    expect { controller.get(monitor_id) }.to raise_error Ragios::MonitorNotFound  
    generic_monitor.state.should == "passed"
    generic_monitor.passed? == true    
  end
  
  after(:all) do
    Couchdb.delete Ragios::CouchdbAdmin.monitors, auth_session
    Couchdb.delete Ragios::CouchdbAdmin.activity_log, auth_session
    Couchdb.delete Ragios::CouchdbAdmin.auth_session, auth_session    
  end
end
