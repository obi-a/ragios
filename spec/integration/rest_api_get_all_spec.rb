require 'spec_base.rb'
require 'rest_client'
require 'yajl'
# needs to run on a blank database
describe "Rest API Get all monitors" do
  before(:each) do
   auth = RestClient.post 'http://localhost:5041/session', { :username=> 'admin', :password => 'ragios'}
   hash = Yajl::Parser.parse(auth.to_str)
   @auth_session = hash['AuthSession']
   @options = {:content_type => :json,
               :cookies => {:AuthSession => @auth_session}}
   @auth_cookie =  {:cookies => {:AuthSession => @auth_session}}            
  end
  
  it "retrieves all monitors" do
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
   
    response = RestClient.get "http://127.0.0.1:5041/monitors/",@auth_cookie
    response.code.should == 200
    retrieved_monitors = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    retrieved_monitors.first.should include(monitors.first)
   
    #teardown
    response = RestClient.delete "http://127.0.0.1:5041/monitors/#{monitor_id}",@auth_cookie
    response.code.should == 200   
  end  
  
  it "returns an empty array when there is no monitor" do
    response = RestClient.get "http://127.0.0.1:5041/monitors",@auth_cookie
    response.code.should == 200
    response.body.should == '[]'
  end
end    
  
  
