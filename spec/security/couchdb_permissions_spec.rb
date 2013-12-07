require 'spec_base.rb'

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'test_couchdb_security',
                               activity_log: 'test_couchdb_security',
                               auth_session: 'test_couchdb_security'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 } 

Ragios::CouchdbAdmin.config(database_admin)

admin = Ragios::Admin
database = Ragios::CouchdbAdmin.auth_session
auth_session = Ragios::CouchdbAdmin.session

describe "Couchdb Security" do
  before(:all) do
    Ragios::CouchdbAdmin.create_database
  end

  describe "monitors database" do
    it "should return security object of monitors database" do
      database_admin = Ragios::CouchdbAdmin.admin
      hash = Couchdb.get_security(Ragios::CouchdbAdmin.monitors,Ragios::CouchdbAdmin.session)
      admins = hash["admins"]
      readers = hash["readers"]
      admins["names"].should == [database_admin[:username]]
      admins["roles"].should == ["admin"]
      readers["names"].should == [database_admin[:username]]
      readers["roles"].should == ["admin"]
    end
  end

  describe "activity log database" do
    it "should return security object of activity log database" do
      database_admin = Ragios::CouchdbAdmin.admin
      hash = Couchdb.get_security(Ragios::CouchdbAdmin.activity_log,Ragios::CouchdbAdmin.session)
      admins = hash["admins"]
      readers = hash["readers"]
      admins["names"].should == [database_admin[:username]]
      admins["roles"].should == ["admin"]
      readers["names"].should == [database_admin[:username]]
      readers["roles"].should == ["admin"]     
    end
  end

  describe "authsession database" do
    it "should return security object of authsession database" do
      database_admin = Ragios::CouchdbAdmin.admin
      hash = Couchdb.get_security(Ragios::CouchdbAdmin.auth_session,Ragios::CouchdbAdmin.session)
      admins = hash["admins"]
      readers = hash["readers"]
      admins["names"].should == [database_admin[:username]]
      admins["roles"].should == ["admin"]
      readers["names"].should == [database_admin[:username]]
      readers["roles"].should == ["admin"]   
    end
  end

  after(:all) do
    Couchdb.delete database, auth_session
  end  
end
