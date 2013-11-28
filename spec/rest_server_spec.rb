require 'spec_base.rb'
require 'rest_client'
require 'yajl'

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_rest_api_monitors',
                               activity_log: 'test_rest_api_activity_log',
                               auth_session: 'test_rest_api_auth_session'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 } 

Ragios::CouchdbAdmin.config(database_admin)
auth_session = Ragios::CouchdbAdmin.session 

Ragios::Controller.scheduler(Ragios::Scheduler.new(Ragios::Controller))
Ragios::Controller.model(Ragios::Model::CouchdbMonitorModel)
Ragios::Controller.logger(Ragios::CouchdbLogger.new)

describe "Ragios REST API" do
  it "adds a monitor" do
    monitors = [{monitor: "My Website",
      url: "http://mysite.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier",
      plugin: "url_monitor" }]
      
      str = Yajl::Encoder.encode(monitor)
      response = RestClient.post "http://127.0.0.1:5041/monitors/", str, {:content_type => :json, :accept => :json,:cookies => {:AuthSession => @auth_session}}
      response.code.should == 200      
      puts response.inspect
  end


end
