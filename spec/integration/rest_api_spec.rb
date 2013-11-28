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
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{returned_monitors.first[:_id]}",{:cookies => {:AuthSession => @auth_session}}
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
      plugin: "url_monitor" }]  

    str = Yajl::Encoder.encode(monitors)
    begin
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, @options  
    rescue => e
      e.response.should == '{"error":"No Notifier Found"}'
    end
  end
end
