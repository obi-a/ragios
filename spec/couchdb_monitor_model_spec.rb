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
    monitor_id = UUIDTools::UUID.random_create.to_s 
    monitors = [{monitor: "something",
                 via: "mock_notifier",
                 _id: monitor_id,
                 plugin: "mock_plugin" }]
    model.save(monitors)
    doc = {:database => database, :doc_id => monitor_id}
    hash = Couchdb.view doc,auth_session,symbolize_keys: true
    hash.should include(monitors.first)    
    hash.should include(:_rev)
    Couchdb.delete_doc doc,auth_session
  end
  
  it "should delete a monitor" do 
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin" 
           }
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session
    
    model.delete(monitor_id)
    doc = {:database => database, :doc_id => monitor_id}
    expect { Couchdb.view doc,auth_session }.to raise_error(CouchdbException, "CouchDB: Error - not_found. Reason - deleted")
  end
  
  it "should raise error when attempting to delete a monitor that doesn't exist" do
    expect { model.delete("dont_exist") }.to raise_error(Ragios::MonitorNotFound)
  end
  
  it "should find monitor by id" do
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin" }
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session
    
    monitor = model.find(monitor_id)   
    monitor.should include(data)        
    Couchdb.delete_doc doc,auth_session 
  end
  
  it "should raise error when attempting to find a monitor that dosen't exist" do
    expect { model.find("dont_exist") }.to raise_error(Ragios::MonitorNotFound)  
  end
  
  it "should update a monitor by id" do
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin" }
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session
    options = {via: "new_notifier", plugin: "new_plugin"}
    model.update(monitor_id, options)
    
    doc = {:database => database, :doc_id => monitor_id}
    hash = Couchdb.view doc,auth_session, symbolize_keys: true
    hash.should include(options)    
    Couchdb.delete_doc doc,auth_session      
  end
  
  it "should raise error when attempting to update a monitor that dosen't exist" do
    expect { model.update("dont_exist",{via: "new_notifier", plugin: "new_plugin"} ) }.to raise_error(Ragios::MonitorNotFound)  
  end  
  
  it "should find monitors with matching attributes" do
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin" ,
            tag: "my monitors"}
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session
    
    monitors = model.where(plugin: "mock_plugin", tag: "my monitors")  
    monitors.first.should include(data)    
    monitors.length.should == 1   
    Couchdb.delete_doc doc,auth_session 
  end
  
  it "should return empty when no matching attributes is found" do
    monitors = model.where(plugin: "dont_exist_plugin", tag: "dont_exist")  
    monitors.should == []
  end
  
  it "should return all active monitors" do 
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin",
            status_: "active"}
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session  
  
    monitors = model.active_monitors
    monitors.length.should == 1
    monitors.first.should include(data)   
    Couchdb.delete_doc doc,auth_session    
  end
  
  it "should return empty when no monitor is active" do
    monitors = model.active_monitors
    monitors.should == []
  end
  
  it "should return all monitors" do
    monitor_id = UUIDTools::UUID.random_create.to_s
    data = {monitor: "something",
            _id: monitor_id,
            via: "mock_notifier",
            plugin: "mock_plugin"}
    doc = {:database => database, :doc_id => monitor_id, :data => data}
    Couchdb.create_doc doc,auth_session 
    
    monitors = model.all
    monitors.length.should == 1
    monitors.first.should include(data)
    Couchdb.delete_doc doc,auth_session    
  end
  
  it "should return empty for all monitors when there is no monitor" do
    monitors = model.all
    monitors.should == []
  end
  
  after(:all) do
    Couchdb.delete database, auth_session
  end
end
