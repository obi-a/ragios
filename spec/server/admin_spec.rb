require 'spec_base.rb'

describe "monitors" do
  it "should authenticate admin user" do
    ragios_admin_user = {username: 'test',
                     password: '1234',
                     auth_timeout: 900} 
    Ragios::Admin.config(ragios_admin_user)
    
    Ragios::Admin.authenticate?('test','1234').should == true
    Ragios::Admin.authenticate?('nothing','nothing').should == false    
  end

  it "should validate and invalidate a token" do 
    ragios_admin_user = {username: 'test',
                          password: '1234',
                           auth_timeout: 900} 
    Ragios::Admin.config(ragios_admin_user)
    token = Ragios::Admin.session
    invalid = '1234567890'
    Ragios::Admin.valid_token?(token).should == true
    Ragios::Admin.valid_token?(invalid).should == false
    Ragios::Admin.valid_token?(nil).should == false
  end

  it "should invalidate an expired token and validate a non-expired token" do 
    ragios_admin_user = {username: 'test',
                          password: '1234',
                           auth_timeout: 900} 
    Ragios::Admin.config(ragios_admin_user)
    token = Ragios::Admin.session
    Ragios::Admin.valid_token?(token).should == true

    #expire the token with old timestamp
    doc = { :database => Ragios::CouchdbAdmin.auth_session, :doc_id => token, :data => {:timestamp => 1375576871 }}   
    Couchdb.update_doc doc,Ragios::CouchdbAdmin.session
    Ragios::Admin.valid_token?(token).should == false

    #unexpire the token with current timestamp
    doc = { :database => Ragios::CouchdbAdmin.auth_session, :doc_id => token, :data => {:timestamp => Time.now.to_i }}   
    Couchdb.update_doc doc,Ragios::CouchdbAdmin.session
    Ragios::Admin.valid_token?(token).should == true
  end
end
