require 'spec_base.rb'

admin = Ragios::Admin

describe Ragios::Admin do
  before(:all) do
    #database configuration
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: 'ragios_test_ragios_admin_database',
      address: 'http://localhost',
      port: '5984'
    }
    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
    @database = Ragios::CouchdbAdmin.get_database
  end

  describe "#invalidate_token" do
    it "deletes a valid token and returns true" do
      valid_token = admin.session
      admin.invalidate_token(valid_token).should == true
    end
    it "returns false when token is blank" do
      admin.invalidate_token("").should == false
      admin.invalidate_token(nil).should == false
    end
    it "returns false when token is not found" do
      admin.invalidate_token("not_found_token").should == false
    end
  end

  describe "#authenticate?" do
    it "returns true when credentials are valid" do
      username = "tester"
      password = "12345"
      admin.config(username: username, password: password)
      admin.authenticate?(username, password).should == true
    end
    it "returns false when credentials as invalid" do
      username = "tester"
      password = "12345"
      admin.config(username: "something else", password: "something else")
      admin.authenticate?(username, password).should == false
    end
  end

  describe "#do_authentication?" do
    it "returns config authentication settings" do
      admin.config(authentication: true)
      admin.do_authentication?.should == true
      admin.config(authentication: false)
      admin.do_authentication?.should == false
    end
  end

  describe "#valid_token?" do
    it "returns true when authentication is false" do
      admin.config(
        username: "something",
        password: "12345",
        timeout: 900,
        authentication: false
      )
      admin.valid_token?(nil).should == true
    end
    it "returns true when there is no authentication attribute" do
      admin.config(
        username: "something",
        password: "12345",
        timeout: 900,
      )
      admin.valid_token?(nil).should == true
    end
    it "returns false when token is blank" do
      admin.config(authentication: true)
      admin.valid_token?("").should == false
      admin.valid_token?(nil).should == false
    end
    it "returns false when token is not found in database" do
      admin.config(authentication: true)
      admin.valid_token?("not_found_token").should == false
    end
    it "returns false when no auth_timeout is provided" do
      admin.config(
        username: "something",
        password: "12345",
        authentication: true
      )
      token = admin.session
      admin.valid_token?(token).should == false
    end
    it "returns true when token has not expired" do
      admin.config(
        username: "something",
        password: "12345",
        auth_timeout: 900,
        authentication: true
      )
      token = admin.session
      admin.valid_token?(token).should == true
    end
    it "returns false when token has expired" do
      admin.config(
        username: "something",
        password: "12345",
        auth_timeout: 0,
        authentication: true
      )
      token = admin.session
      admin.valid_token?(token).should == false
      #token gets deleted
      expect {@database.get_doc(token)}.to raise_error Leanback::CouchdbException
    end
  end
  after(:all) do
    @database.delete
  end
end
