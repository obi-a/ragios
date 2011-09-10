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
                   via: 'gmail',  
                   notify_interval: '6h'
                    }
     
     #add init values to plugin
     Monitors::Url.class_eval do |options|
       include Ragios::InitValues
     end

    @plugin = Monitors::Url.new
    @plugin.init(options)
     Ragios::GenericMonitor.class_eval do |options|
       include Ragios::InitValues
     end
    @generic_monitor = Ragios::GenericMonitor.new(@plugin,options) 
    
    @generic_monitor.test_command.should == true
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
                   via: 'gmail',  
                   notify_interval: '6h'
                    }]
     monitors =  Ragios::Monitor.start monitoring,server=TRUE
     #ensure that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor
     monitors[0].test_command.should == true
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash     
  end

 it "should restart monitors saved on the server" do
     monitors = Ragios::Monitor.restart
     monitors[0].class.should == Ragios::GenericMonitor
   
     monitors[0].test_command.boolean?.should ==  true
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
                   via: 'gmail',  
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

      doc = {:database => 'monitors', :doc_id => 'monitor_monitor', :data => data}
     begin
      Document.create doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

     monitors = Ragios::Monitor.restart(id = 'monitor_monitor') 

     monitors[0].class.should == Ragios::GenericMonitor
   
     monitors[0].test_command.boolean?.should ==  true
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.should_not == nil
     sch.class.should ==  Hash        
 end 
 
  it "should try to restart an already running monitor but returns false" do
     Ragios::Monitor.restart(id = 'monitor_monitor').should == nil 
     #delete the sample monitor used in this test from database to provide an accurate test on each run
     Ragios::Server.delete_monitor(id ='monitor_monitor')
  end
   
end
