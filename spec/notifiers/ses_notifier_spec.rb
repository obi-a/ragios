require 'spec_base.rb'

describe Ragios::SESNotifier do
    it "should send a notification message via ses" do
         message = {:to => "obi.akubue@gmail.com",
                    :subject =>"Test notification message from Ragios via ses", 
                     :body => "stuff"}
   
      Ragios::SESNotifier.new.send message
   end
end

describe Ragios::Monitor do
   it "should create a generic monitor and send a notification messages (FAILED/FIXED) via ses" do
       monitoring = [{ tag: 'test',
                   monitor: 'url',
                   every: '1m',
                   test: 'Generic monitor test notification',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@gmail.com',
                   via: 'ses',  
                   notify_interval: '6h'
                    }]
     Ragios::Server.init
     monitors =  Ragios::Monitor.start monitoring,server=TRUE
     #verify that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor
     monitors[0].notify
     monitors[0].fixed
   end
end

describe Ragios::Server do
 it "should send out a status report via ses" do

   #create sample monitor for generating a test sample update 
   data = { tag: 'monitor_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@gmail.com',
                   via: 'ses',  
                   notify_interval:'3h',
                   describe_test_result:  "sample monitor for specs",
        	   time_of_last_test: "2:30pm",
         	   num_tests_passed: "10",
         	   num_tests_failed: "20",
                   total_num_tests: "30",
                   last_test_result: "PASSED", 
                   status: "UP",
                   state: "active"
                  }

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'monitor_monitor2', :data => data}
     begin
      Couchdb.create_doc doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

       data = { tag: 'monitor_monitor', 
                   monitor: 'url',
                   every: '1m',
                   test: '3 test',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@gmail.com',
                   via: 'ses',  
                   notify_interval:'3h',
                   describe_test_result:  "sample monitor for specs",
        	   time_of_last_test: "2:30pm",
         	   num_tests_passed: "10",
         	   num_tests_failed: "20",
                   total_num_tests: "30",
                   last_test_result: "FAILED", 
                   status: "UP",
                   state: "active"
                  }

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'monitor_monitor3', :data => data}
     begin
      Couchdb.create_doc doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 
  
   @body = Ragios::Server.status_report('monitor_monitor') 
   message = {:to => 'obi.akubue@gmail.com',
               :subject => 'Ragios Status Report', 
                  :body => @body}
   Ragios::SESNotifier.new.send message
   #delete the sample monitor used in this test from database to provide an accurate test on each run
   Ragios::Server.delete_monitor(id ='monitor_monitor2')   
   Ragios::Server.delete_monitor(id ='monitor_monitor3')              
 end
end

