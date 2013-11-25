require 'spec_base.rb'

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_ragios_admin',
                               activity_log: 'test_ragios_admin',
                               auth_session: 'test_ragios_admin'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 } 

Ragios::CouchdbAdmin.config(database_admin)

admin = Ragios::Admin
database = Ragios::CouchdbAdmin.auth_session
auth_session = Ragios::CouchdbAdmin.session

describe Ragios::Admin do
  before(:all) do
    Ragios::CouchdbAdmin.create_database
  end
  
  before(:each) do
    ragios_admin_user = {username: 'test',
                         password: '1234',
                         auth_timeout: 900} 
    admin.config(ragios_admin_user)
  end
  
  it "should authenticate admin user" do    
   admin.authenticate?('test','1234').should == true
   admin.authenticate?('nothing','nothing').should == false    
  end

  it "should validate and invalidate a token" do 
    token = admin.session
    invalid = '1234567890'
    admin.valid_token?(token).should == true
    admin.valid_token?(invalid).should == false
    admin.valid_token?(nil).should == false
  end

  it "should invalidate an expired token and validate a non-expired token" do 
    token = admin.session
    admin.valid_token?(token).should == true

    #expire the token with old timestamp
    doc = { :database => Ragios::CouchdbAdmin.auth_session, :doc_id => token, :data => {:timestamp => 1375576871 }}   
    Couchdb.update_doc doc,Ragios::CouchdbAdmin.session
    admin.valid_token?(token).should == false

    #unexpire the token with current timestamp
    doc = { :database => Ragios::CouchdbAdmin.auth_session, :doc_id => token, :data => {:timestamp => Time.now.to_i }}   
    Couchdb.update_doc doc,Ragios::CouchdbAdmin.session
    admin.valid_token?(token).should == true
  end
  
  after(:all) do
    Couchdb.delete database, auth_session
  end  
end
