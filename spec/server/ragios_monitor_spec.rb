require 'spec_base.rb'

class Object
 def boolean?
  self.is_a?(TrueClass) || self.is_a?(FalseClass) 
 end
end



Ragios::Server.init

describe Ragios::GenericMonitor do

 it "should create a generic monitor and plugin. And then run their tests" do
   
    options = { tag: 'admin',
                 monitor: 'url',
                   every: '1m',
                   test: 'is google UP',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h'
                    }
     
     #add init values to plugin
     Ragios::Monitors::Url.class_eval do |options|
       include Ragios::InitValues
     end
    #create plugin
    @plugin = Ragios::Monitors::Url.new
    @plugin.init(options)

    #add init values to generic monitor
     Ragios::GenericMonitor.class_eval do |options|
       include Ragios::InitValues
     end
    #create generic monitor
    @generic_monitor = Ragios::GenericMonitor.new(@plugin,options) 
    #generic monitor executes the plugin

    #Run the generic monitor's test_command
    @generic_monitor.test_command.should == true
    #Run the plugin's test_command
    @plugin.test_command.should == true
  end 
end

describe Ragios::Monitor do
  it "should start monitoring with the server" do
      monitoring = [{ tag: 'test',
                   monitor: 'url',
                   every: '1m',
                   test: 'is google UP',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h'
                    }]
     monitors =  Ragios::Monitor.start monitoring,server=TRUE
     #verify that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor
     monitors[0].test_command.should == true
     #verify that the scheduler is running
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash     
  end

 it "should restart monitors saved on the server" do
     monitors = Ragios::Monitor.restart_monitors
     #verify that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor   
     monitors[0].test_command.boolean?.should ==  true
     #verify that the scheduler is running
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash     
 end 

 it "should restart a monitor by id " do
     #create sample monitor for generating a test sample update 
   data = { tag: 'monitor_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h',
                   describe_test_result:  "sample monitor for specs",
        	   time_of_last_test: "2:30pm",
         	   num_tests_passed: "10",
         	   num_tests_failed: "20",
                   total_num_tests: "30",
                   last_test_result: "PASSED", 
                   status: "UP",
                   state: "stopped"
                  }

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'monitor_monitor', :data => data}
     
     begin
      Couchdb.create_doc doc,Ragios::DatabaseAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 
  # begin
     monitors = Ragios::Monitor.restart_monitor(id = 'monitor_monitor') 

     monitors[0].class.should == Ragios::GenericMonitor
   
     monitors[0].test_command.boolean?.should ==  true
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash    
   #rescue => e
    # e.to_s.should == 
   #end
 end 
 
  it "should not restart an already running monitor" do
    monitor = Ragios::Monitor.restart_monitor(id = 'monitor_monitor')
    monitor["_id"].should == 'monitor_monitor'
    #delete the sample monitor used in this test from database to provide an accurate test on each run
    Ragios::Server.delete_monitor(id ='monitor_monitor')
  end
   
end
