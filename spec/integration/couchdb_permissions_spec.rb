require 'spec_base.rb'

describe "monitors" do
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

describe "activity log" do
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

describe "authsession" do
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
