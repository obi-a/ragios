require 'spec_base.rb'
require 'rest_client'
require 'yajl'

options = {server_scheduler: Ragios::Schedulers::Server.new}
Ragios::Controller.init(options)

describe "REST interface to Ragios Monitor" do

 before(:each) do
   auth = RestClient.post 'http://localhost:5041/session', { :username=> 'admin', :password => 'ragios'}
   hash = Yajl::Parser.parse(auth.to_str)
   @auth_session = hash['AuthSession']
  end
  
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
                   :via => 'gmail_notifier',
                   :notify_interval => '6h',
                   :tag => 'test'   
                  }]
 
      str = Yajl::Encoder.encode(monitor)
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, {:content_type => :json, :accept => :json,:cookies => {:AuthSession => @auth_session}}
      response.code.should == 200
      response.should include('{"ok":"true"}')
      #verify that the monitor was added to the database
      monitors = Ragios::Controller.find_monitors(:url => 'https://add_monitor.com')
      hash = monitors[0]
      hash["url"].should == 'https://add_monitor.com'
      hash["test"].should == 'Sample Test'
      #verify that the monitor is now running in the scheduler
      response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/',{:cookies => {:AuthSession => @auth_session}}
      response.should include(hash["_id"])
      #delete the monitor
      response = RestClient.delete 'http://127.0.0.1:5041/monitors/' + hash["_id"] ,{:cookies => {:AuthSession => @auth_session}}
      response.code.should == 200
      response.should include('{"ok":"true"}')
 end

 it "should return a 500 response because of wrong body in http post request" do
      begin
        RestClient.post "http://127.0.0.1:5041/monitors/", "wrong", {:content_type => :json, :accept => :json,:cookies => {:AuthSession => @auth_session}} 
      rescue => e
        e.response.should == '{"error":"something went wrong"}'
        e.should be_an_instance_of RestClient::InternalServerError
      end
 end
 
it "Should find monitors by key" do
   response = RestClient.get 'http://127.0.0.1:5041/monitors?tag=test',{:cookies => {:AuthSession => @auth_session}}
   response.code.should == 200
   response.should include('"tag":"test"')
   response.should include('"monitor":"url"')
end 

it "should be unable to find value that matches the key" do
  begin
   response = RestClient.get 'http://127.0.0.1:5041/monitors?tag=unknown',{:cookies => {:AuthSession => @auth_session}}
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

      doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'rest_monitor', :data => data}
     begin
      Couchdb.create_doc doc,Ragios::DatabaseAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end  

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "active"},{:content_type => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is now running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.should include("rest_monitor")
end

it "should get monitor by id" do 
  response = RestClient.get 'http://127.0.0.1:5041/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('"monitor":"url"')
  response.should include('"_id":"rest_monitor"')
  response.should include('"every":"1m"')
end

it "should not give an error on restarting a monitor that's already running - put request is idempotent" do
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "active"},{:content_type => :json,:cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
end

it "should not restart a monitor that doesn't exist" do
  begin
  response = RestClient.put 'http://127.0.0.1:5041/monitors/we_dont_exist',{:state => "active"},{:content_type => :json,:cookies => {:AuthSession => @auth_session}}
 rescue => e
  e.response.code.should == 404
  e.response.should == '{"error":"No monitor found with id = we_dont_exist"}'
 end 
end

it "should stop a running monitor and restart it" do
 response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "stopped"},{:content_type => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}') 
  #verify that the monitor is not running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.should_not include("rest_monitor")
  response.should == "[]"

  #put requests are idempotent calling - stopping monitor that is already stopped should not give an error
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "stopped"},{:content_type => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}') 

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "active"},{:content_type => :json,:cookies => {:AuthSession => @auth_session}}
end

it "should try to change a monitor to an unknown state" do
  begin
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "unknown"},{:content_type => :json,:cookies => {:AuthSession => @auth_session}}
   rescue => e
   e.response.should == '{"error":"bad_request"}'
   e.response.code.should == 400
  end 
end



it "should update a running monitor" do
   data  = {     every: '55h',
                   contact: 'admin@aol.com',
                   via: 'gmail_notifier'
                  }
  
  str = Yajl::Encoder.encode(data)

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',str, {:content_type => :json, :accept => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'rest_monitor'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'rest_monitor'
  hash["contact"].should == 'admin@aol.com'
  hash["every"].should == '55h'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.include?("rest_monitor").should == true

  response.include?("55h").should == true
end

it "should update a stopped monitor and remain stopped" do
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "stopped"},{:content_type => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}')

   data  = {     every: '43d',
                   contact: 'bill@java.com',
                   via: 'twitter_notifier'
                  }
  
  str = Yajl::Encoder.encode(data)

  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',str, {:content_type => :json, :accept => :json, :cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}')

  doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => 'rest_monitor'}
  hash = Couchdb.view doc,Ragios::DatabaseAdmin.session
  hash["_id"].should == 'rest_monitor'
  hash["contact"].should == 'bill@java.com'
  hash["every"].should == '43d'
  hash["via"].should == 'twitter_notifier'

  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.should == "[]"
  response = RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor',{:state => "active"},{:content_type => :json, :cookies => {:AuthSession => @auth_session}}
end

it "should get all monitors" do
  response = RestClient.get 'http://127.0.0.1:5041/monitors/',{:cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('"monitor":"url"')
  response.should include('"_id":"rest_monitor"')
end

it "should delete a running monitor" do
  response = RestClient.delete 'http://127.0.0.1:5041/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.code.should == 200
  response.should include('{"ok":"true"}')
  #verify that the monitor is no longer running in the scheduler
  response = RestClient.get 'http://127.0.0.1:5041/scheduler/monitors/rest_monitor',{:cookies => {:AuthSession => @auth_session}}
  response.should == "[]"
end
end
