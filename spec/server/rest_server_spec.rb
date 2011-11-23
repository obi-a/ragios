require 'spec_base.rb'
require 'rest_client'
require 'yajl'

Ragios::Server.init

describe "REST interface to Ragios Monitor" do
  
 it "welcomes you to Ragios" do
    response = RestClient.get 'http://127.0.0.1:5041/', {:content_type => :json}
    response.should include('{"Ragios Server":"welcome"}')
 end
  
 it "Should add monitors to the system and start monitoring them" do 
      monitor = [{ :monitor => 'url',
                   :every => '2m',
                   :test => 'Sample Test',
                   :url => 'https://add_monitor.com',
                   :contact => 'obi.akubue@gmail.com',
                   :via => 'gmail',
                   :notify_interval => '6h',
                   :tag => 'test'   
                  }]
 
      str = Yajl::Encoder.encode(monitor)
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, {:content_type => :json, :accept => :json}
      response.code.should == 200
      response.should include('{"ok":"true"}')
      #verify that the monitor was added to the database
      monitors = Ragios::Server.find_monitors(:url => 'https://add_monitor.com')
      hash = monitors[0]
      hash["url"].should == 'https://add_monitor.com'
      hash["test"].should == 'Sample Test'
      #verify that a monitor is now running in the scheduler
      sch = Ragios::Server.get_status_update_frm_scheduler
      sch.should_not be_nil
      sch.class.should ==  Hash
 end

 it "should return a 500 response because of wrong body in http post request" do
      begin
        RestClient.post "http://127.0.0.1:5041/monitors/", "wrong", {:content_type => :json, :accept => :json} 
      rescue => e
        e.response.should == '{"error":"something went wrong"}'
        e.should be_an_instance_of RestClient::InternalServerError
      end
 end
 
it "Should find monitors by key" do
   response = RestClient.get 'http://127.0.0.1:5041/monitors/tag/test/'
   response.code.should == 200
   response.should include('"tag":"test"')
   response.should include('"monitor":"url"')
end 

it "should be unable to find value that matches the key" do
  begin
   response = RestClient.get 'http://127.0.0.1:5041/monitors/tag/unknown/'
  rescue => e
   e.response.should == '{"error":"not_found"}'
   e.should be_an_instance_of RestClient::ResourceNotFound
  end
end

it "should restart a stopped monitor" do
  data = { tag: 'test', 
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

      doc = {:database => 'monitors', :doc_id => 'rest_monitor', :data => data}
     begin
      Couchdb.create_doc doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
end

it "should not restart a monitor that's already running" do
 begin
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
 rescue => e
  e.response.should == '{"error":"monitor is already active. nothing to restart"}'
  e.should be_an_instance_of RestClient::InternalServerError
 end 
end

it "should not restart a monitor that doesn't exist" do
  begin
  response = RestClient.put 'http://127.0.0.1:5041/monitors/we_dont_exist/state/active',{:content_type => :json}
 rescue => e
  e.response.should == '{"error":"monitor not found"}'
  e.should be_an_instance_of RestClient::ResourceNotFound
 end 
end

it "should delete a monitor" do
  response = RestClient.delete 'http://127.0.0.1:5041/monitors/rest_monitor'
  
end

end
