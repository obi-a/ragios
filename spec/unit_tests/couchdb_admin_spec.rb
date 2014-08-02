require 'spec_base.rb'

describe "CouchDBAdmin" do
  it "creates a new database when one doesn't already exist" do
    database_name = "test_ragios_couchdb_admin_#{Time.now.to_i}"
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: database_name,
      address: 'http://localhost',
      port: '5984'
    }

    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database.should == true
    database = Ragios::CouchdbAdmin.get_database
    database.class.should == Leanback::Couchdb
    #setup_database is idempotent
    Ragios::CouchdbAdmin.setup_database.should == true
    username = database_admin[:username]

    #a security object is only created if a database username is provided
    #otherwise no security object is created,
    #this conditional is provided so that same test will pass when run in couchdb admin party
    #and also pass when run in non-admin party
    if username
      database.security_object.should == {
                                            admins: {names: [username], roles: ["admin"]},
                                            readers: {names: [username],roles: ["admin"]}
                                          }
    else
      database.security_object.should == {}
    end
    #teardown
    Ragios::CouchdbAdmin.get_database.delete
  end
end
