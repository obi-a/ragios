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
  end

  it "adds a monitor" do
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier",
      plugin: "url_monitor" }]
    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options
    
    response.code.should == 200      
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",{:cookies => {:AuthSession => @auth_session}}
    response.code.should == 200
  end
  
  it "adds a monitor with multiple notifiers" do
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier","twitter_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options
    
    response.code.should == 200      
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    returned_monitors.first.should include(monitors.first)
    
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{returned_monitors.first[:_id]}",{:cookies => {:AuthSession => @auth_session}}
    response.code.should == 200  
  end
  
  it "cannot add a monitor with no notifier" do 
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
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
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
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
  
  it "should get a monitor" do
    #setup starts
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier"],
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    
    response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    returned_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    monitor_id = returned_monitors.first[:_id]
   #setup ends
   
    response = RestClient.get "http://127.0.0.1:5041/monitors/#{monitor_id}",{:cookies => {:AuthSession => @auth_session}}
    response.code.should == 200
    get_monitor = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    get_monitor.should include(monitors.first)
    
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",{:cookies => {:AuthSession => @auth_session}}
    response.code.should == 200  
  end
  
  it "should find monitors by multiple keys"
  
  it "should update a monitor"  do
    #setup starts
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
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
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",{:cookies => {:AuthSession => @auth_session}}
    response.code.should == 200      
  end
  
  it "cannot update a monitor with bad data" do
    #setup starts
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
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
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",{:cookies => {:AuthSession => @auth_session}}
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
    end
  end
  
  it "deletes a monitor"
  
end
