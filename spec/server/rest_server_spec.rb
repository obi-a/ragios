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
      #verify that the monitor is now running in the scheduler
      response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/'
      response.should include(hash["_id"])
      #delete the monitor
      response = RestClient.delete 'http://127.0.0.1:5041/monitors/' + hash["_id"] 
      response.code.should == 200
      response.should include('{"ok":"true"}')
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
      Couchdb.create_doc doc,Ragios::DatabaseAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is now running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor'
  response.should include("rest_monitor")
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

it "should stop a running monitor and restart it" do
 response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/stopped',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is now running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor'
  response.should_not include("rest_monitor")
  response.should == "[]"
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
end

it "should try to change a monitor to an unknown state" do
  begin
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/unknown',{:content_type => :json}
   rescue => e
   e.response.should == '{"error":"something went wrong"}'
   e.response.code.should == 500
  end 
end



it "should update a running monitor" do
   data  = {     every: '55h',
                   contact: 'admin@aol.com',
                   via: 'gmail'
                  }
  
  str = Yajl::Encoder.encode(data)

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',str, {:content_type => :json, :accept => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => 'monitors', :doc_id => 'rest_monitor'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'rest_monitor'
  hash["contact"].should == 'admin@aol.com'
  hash["every"].should == '55h'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor'
  response.include?("rest_monitor").should == true

  response.include?("55h").should == true
end

it "should update a stopped monitor and remain stopped" do
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/stopped',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

   data  = {     every: '43d',
                   contact: 'bill@java.com',
                   via: 'twitter'
                  }
  
  str = Yajl::Encoder.encode(data)

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',str, {:content_type => :json, :accept => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => 'monitors', :doc_id => 'rest_monitor'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'rest_monitor'
  hash["contact"].should == 'bill@java.com'
  hash["every"].should == '43d'
  hash["via"].should == 'twitter'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor'
  response.should == "[]"
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
end

it "should delete a running monitor" do
  response = RestClient.delete 'http://127.0.0.1:5041/monitors/rest_monitor'
  response.code.should == 200
  response.should include('{"ok":"true"}')
  #verify that the monitor is no longer running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor'
  response.should == "[]"
end

#status updates 
it "should return status updates with tagg 'test'" do
  response = RestClient.get 'http://127.0.0.1:5041/status_updates/tag/test/'
  response.code.should == 200
  response.should include('"tag":"test"')
  response.should include('"_id":"test_config_settings"')
end

it "should get all status updates" do
  response = RestClient.get 'http://127.0.0.1:5041/status_updates'
  response.code.should == 200
  response.should include('"tag":"test"')
  response.should include('"_id":"test_config_settings"')
end

it "should get a status update by id" do 
  response = RestClient.get 'http://127.0.0.1:5041/status_updates/test_config_settings'
  response.code.should == 200
  response.should include('"tag":"test"')
  response.should include('"_id":"test_config_settings"')
  response.should include('"every":"1m"')
  response.should include('"contact":"admin@mail.com"')
end

it "should be unable to get status update that matches the tag" do
  begin
   response = RestClient.get 'http://127.0.0.1:5041/status_updates/tag/unknown/'
  rescue => e
   e.response.should == '{"error":"not_found"}'
   e.should be_an_instance_of RestClient::ResourceNotFound
  end
end

it "Should add status updates to the system and start running them" do 
      config = {   :every => '24h',
                   :contact => 'user@mail.com',
                   :via => 'gmail',
                  :tag => 'config_status_update_test',                  
                  }
 
      str = Yajl::Encoder.encode(config)
      response = RestClient.post "http://127.0.0.1:5041/status_updates/", str, {:content_type => :json, :accept => :json}
      response.code.should == 200
      response.should include('{"ok":"true"}')
      #verify that the status update was added to the database
      config = Ragios::Server.find_status_update(:tag => 'config_status_update_test')
      hash = config[0]
      hash["tag"].should == 'config_status_update_test'
      hash["every"].should == '24h'
      hash["contact"].should == 'user@mail.com'
      #verify that the status update is now running in the scheduler
      response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/config_status_update_test'
      response.should include(hash["tag"])
      #delete the status update
      response = RestClient.delete 'http://127.0.0.1:5041/status_updates/config_status_update_test' 
      response.code.should == 200
      response.should include('{"ok":"true"}')
 end

 it "should return a 500 response because of wrong body in the status update http post request" do
      begin
        RestClient.post "http://127.0.0.1:5041/status_updates/", "wrong", {:content_type => :json, :accept => :json} 
      rescue => e
        e.response.should == '{"error":"something went wrong"}'
        e.should be_an_instance_of RestClient::InternalServerError
      end
 end

it "should restart a stopped status update" do
  config = {   :every => '1m',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                  :tag => 'this_status_update', 
                  :state => 'stopped'
                  }
       doc = {:database => 'status_update_settings', :doc_id => 'just_nother_status_update', :data => config}
     begin
      Couchdb.create_doc doc,Ragios::DatabaseAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end  

  response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/active/',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is now running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/this_status_update'
  response.should include("this_status_update")
end

it "should not restart a status update that's already running" do
 begin
  response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/active',{:content_type => :json}
 rescue => e
  e.response.should == '{"error":"no stopped status update found for named tag"}'
  e.response.code.should == 404
 end 
end

it "should stop a running status update and restart it" do
 response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/stopped',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is now running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/this_status_update'
  response.should_not include("rest_monitor")
  response.should == "[]"
  response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/active',{:content_type => :json}
end

it "should try to change a status update to an unknown state" do
  begin
   response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/unknown',{:content_type => :json}
  rescue => e 
   #TODO change up the design to get this handled properly, with an appropriate error message
   e.response.should == '<h1>Internal Server Error</h1>'
   e.response.code.should == 500
  end 
end

it "should update a running status update" do
   data  = {     every: '96d',
                   contact: 'james@yarn.com',
                   via: 'email'
                  }
  
  str = Yajl::Encoder.encode(data)

  response = RestClient.put 'http://127.0.0.1:5041/status_updates/just_nother_status_update',str, {:content_type => :json, :accept => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => 'status_update_settings', :doc_id => 'just_nother_status_update'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'just_nother_status_update'
  hash["contact"].should == 'james@yarn.com'
  hash["every"].should == '96d'
  hash["via"].should == 'email'
  hash["tag"].should == 'this_status_update'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/this_status_update'
  response.include?("this_status_update").should == true
  response.include?("96d").should == true
end

it "should update a stopped status update and remain stopped" do
  response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/stopped',{:content_type => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

   data  = { every: '18m',
                   contact: 'skyla@ateam.com',
                   via: 'twitter'
                  }
  
  str = Yajl::Encoder.encode(data)
  response = RestClient.put 'http://127.0.0.1:5041/status_updates/just_nother_status_update',str, {:content_type => :json, :accept => :json}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => 'status_update_settings', :doc_id => 'just_nother_status_update'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'just_nother_status_update'
  hash["contact"].should == 'skyla@ateam.com'
  hash["every"].should == '18m'
  hash["via"].should == 'twitter'
  hash["tag"].should == 'this_status_update'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/this_status_update'
  response.should == "[]"
  response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/active',{:content_type => :json}
end

it "should delete a running status update" do
  response = RestClient.delete 'http://127.0.0.1:5041/status_updates/this_status_update'
  response.code.should == 200
  response.should include('{"ok":"true"}')
  #verify that the monitor is no longer running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/status_updates/this_status_update'
  response.should == "[]"
end

end
