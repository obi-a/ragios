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
    Ragios::CouchdbAdmin.get_database.class.should == Leanback::Couchdb
    #setup_database is idempotent
    Ragios::CouchdbAdmin.setup_database.should == true
    #teardown
    Ragios::CouchdbAdmin.get_database.delete
  end
end
