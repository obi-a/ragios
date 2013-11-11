require 'spec_base.rb'

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_ragios_model',
                               activity_log: 'test_ragios_model',
                               auth_session: 'test_ragios_model'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 } 

Ragios::CouchdbAdmin.config(database_admin)

model  = Ragios::Model::CouchdbMonitorModel
database = Ragios::CouchdbAdmin.monitors
auth_session = Ragios::CouchdbAdmin.session 

describe "Ragios::Model::CouchdbMonitorModel" do
  before(:all) do
    Ragios::CouchdbAdmin.create_database
  end

  it "should save a monitor" do
    monitors = [{monitor: "something",
               via: "mock_notifier",
               _id: "monitor_id",
               plugin: "mock_plugin" }]
    model.save(monitors)
    doc = {:database => database, :doc_id => "monitor_id"}
    hash = Couchdb.view doc,auth_session
    hash.should include("monitor"=> "something", "via"=> "mock_notifier","_id"=> "monitor_id","plugin"=>"mock_plugin")    
    hash.should include("_rev")
    Couchdb.delete_doc doc,auth_session
  end
  
  after(:all) do
    Couchdb.delete database, auth_session
  end
end
