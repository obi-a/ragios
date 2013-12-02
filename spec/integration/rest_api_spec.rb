require 'spec_base.rb'
require 'rest_client'
require 'yajl'

describe "Ragios REST API" do
  before(:each) do
   auth = RestClient.post 'http://localhost:5041/session', { :username=> 'admin', :password => 'ragios'}
   hash = Yajl::Parser.parse(auth.to_str)
   @auth_session = hash['AuthSession']
   @options = {:content_type => :json,
               :cookies => {:AuthSession => @auth_session}}
   @auth_cookie =  {:cookies => {:AuthSession => @auth_session}}            
  end

  it "adds a monitor" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier",
      plugin: "url_monitor" }]
    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options
    
    response.code.should == 200      
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    response.code.should == 200
  end
  
  it "adds a monitor with multiple notifiers" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier","twitter_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options
    
    response.code.should == 200      
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    returned_monitors.first.should include(monitors.first)
    
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{returned_monitors.first[:_id]}",@auth_cookie
    response.code.should == 200  
  end
  
  it "cannot add a monitor with no notifier" do 
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier"}]  

    str = Yajl::Encoder.encode(monitors)
    begin
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    rescue => e
      e.response.should include('{"error":"No Plugin Found')
    end
  end
  
  it "cannot add a monitor with no plugin" do
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    begin
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    rescue => e
      e.response.should include('{"error":"No Notifier Found')
    end  
  end
  
  it "cannot add a badly formed monitor" do 
    begin
      RestClient.post "http://127.0.0.1:5041/monitors/", "bad data", @options
    rescue => e
      e.should be_an_instance_of RestClient::InternalServerError
      e.response.code.should == 500
    end    
  end
  
  it "should retrieve a monitor by id" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
   #setup ends
   
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}/",@auth_cookie
    response.code.should == 200
    retrieved_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    retrieved_monitor.should include(monitors.first)
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    response.code.should == 200  
  end
   
  it "should find monitors that match multiple key/value pairs"  do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor",
      tag: "test" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends   
    
    response = RestClient.get "http://127.0.0.1:5041/monitors?tag=test&every=5m&monitor=#{CGI.escape unique_name}", @auth_cookie
    response.code.should == 200
    found_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    found_monitors.first.should include(monitors.first)
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200    
  end
  
  it "returns an empty array when no monitor matches multiple key/value pairs" do
    response = RestClient.get "http://127.0.0.1:5041/monitors?something=dont_exist&every=5m&monitor=dont_exist", @auth_cookie
    response.code.should == 200
    response.body.should == '[]'
  end
  
  it "should update a monitor"  do
    #setup starts
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends  
    
    update_options = {every: "10m", via: ["twitter_notifier"]}
    
    str = Yajl::Encoder.encode(update_options)
    
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",str, @options
    response.code.should == 200   
    updated_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    updated_monitor.should include(update_options)
    updated_monitor[:status_].should == "active"
    
    #monitor update is idempotent
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",str, @options
    response.code.should == 200   
    updated_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    updated_monitor.should include(update_options)
    updated_monitor[:status_].should == "active"    
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200      
  end
  
  it "cannot update a monitor with bad data" do
    #setup starts
    monitors = [{monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends  
    begin
      response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}","bad data", @options  
    rescue => e
      e.should be_an_instance_of RestClient::InternalServerError    
      e.response.code.should == 500
    end  
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200         
  end
  
  it "cannot update a monitor that don't exist" do
    update_options = {every: "5m", via: ["twitter_notifier"]}
    str = Yajl::Encoder.encode(update_options)
    monitor_id = "dont_exist"
    begin
      response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",str, @options
    rescue => e
      e.response.should include('{"error":"No monitor found with id = dont_exist"}')
      e.response.code.should == 404
    end
  end
  
  it "deletes a monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier",
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends   
    
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200
     
    begin
      RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie 
    rescue => e
      e.response.code.should == 404
      e.response.should include('{"error":"No monitor found with id =')
    end
  end
  
  it "cannot delete a monitor that don't exist" do
    monitor_id = "dont_exist"
    begin
      RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    rescue => e
      e.response.code.should == 404
      e.response.should include('{"error":"No monitor found with id = dont_exist"}')
    end
  end
  
  
  it "stops an active monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends 
    
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    active_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)  
    active_monitor[:status_].should == "active"    
    
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "stopped"},@options
    response.code.should == 200
    
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    stopped_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)  
    stopped_monitor[:status_].should == "stopped"
    
    #stopping a monitor is idempotent
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "stopped"},@options
    response.code.should == 200    
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200       
  end
  
  it "cannot stop a monitor that don't exist" do
    monitor_id = "dont_exist"
    begin  
      RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "stopped"},@options 
    rescue => e
      e.response.code.should == 404
      e.response.should include('{"error":"No monitor found with id = dont_exist"}')
    end     
  end
  
  it "restarts a stopped monitor" do
    #setup starts
    unique_name = "Google #{Time.now.to_i}"
    monitors = [{monitor: unique_name,
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    #setup ends 
    
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "stopped"},@options
    response.code.should == 200 
    
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    stopped_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)  
    stopped_monitor[:status_].should == "stopped"      
    
    
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "active"},@options
    response.code.should == 200 
    
    
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    stopped_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)  
    stopped_monitor[:status_].should == "active" 
    
    #monitor restart is idempotent
    response = RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "active"},@options
    response.code.should == 200  
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}", @auth_cookie
    response.code.should == 200      
  end
  
  it "cannot restart a monitor that don't exist" do
    monitor_id = "dont_exist"
    begin  
      RestClient.put "http://127.0.0.1:5041/monitors/#{monitor_id}",{:status => "active"},@options 
    rescue => e
      e.response.code.should == 404
      e.response.should include('{"error":"No monitor found with id = dont_exist"}')
    end     
  end  
  
  it "rejects bad requests" do
    expect{ RestClient.get "http://127.0.0.1:5041/xyz" }.to raise_error(RestClient::BadRequest)
    expect{ RestClient.put "http://127.0.0.1:5041/xyz",{status: "stopped"} }.to raise_error(RestClient::BadRequest)
    expect{ RestClient.delete "http://127.0.0.1:5041/xyz" }.to raise_error(RestClient::BadRequest)
    expect{ RestClient.post "http://127.0.0.1:5041/xyz", '{"monitor":"something"}'}.to raise_error(RestClient::BadRequest)
    expect{ RestClient.put "http://127.0.0.1:5041/xyz","update_data"}.to raise_error(RestClient::BadRequest)
  end
  
  it "will reject incorrect admin credentials" do
    begin
      RestClient.post 'http://localhost:5041/session', { :username=> 'wrong_username', :password => 'wrong_password'}
    rescue => e
      e.response.code.should == 401
      e.response.should == '{"error":"You are not authorized to access this resource"}'
    end
  end
  
  
  it "will reject unauthorized requests" do
    begin
      RestClient.get "http://127.0.0.1:5041/monitors/some_monitor"
    rescue => e
      e.response.code.should == 401
      e.response.should == '{"error":"You are not authorized to access this resource"}'
    end   
    
    begin
      RestClient.put "http://127.0.0.1:5041/monitors/some_monitor",{status: "active"}
    rescue => e
      e.response.code.should == 401
      e.response.should == '{"error":"You are not authorized to access this resource"}'
    end  
    
    expect{ RestClient.get "http://127.0.0.1:5041/monitors" }.to raise_error(RestClient::Unauthorized)
    expect{ RestClient.put "http://127.0.0.1:5041/monitors/some_monitor",{status: "stopped"} }.to raise_error(RestClient::Unauthorized)
    expect{ RestClient.delete "http://127.0.0.1:5041/monitors/some_monitor" }.to raise_error(RestClient::Unauthorized)
    expect{ RestClient.post "http://127.0.0.1:5041/monitors/", '{"monitor":"something"}'}.to raise_error(RestClient::Unauthorized)
    expect{ RestClient.put "http://127.0.0.1:5041/monitors/monitor_id","update_data"}.to raise_error(RestClient::Unauthorized)
    
  end
   
end
