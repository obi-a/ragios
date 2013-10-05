module Ragios
  class Admin
    attr_accessor :username
    attr_accessor :password
    attr_accessor :auth_timeout

    def self.config(ragios_admin)
      @username = ragios_admin[:username]
      @password = ragios_admin[:password]
      @auth_timeout = ragios_admin[:auth_timeout]
    end

    def self.admin
       admin = {username: @username,
                 password: @password,
                  auth_timeout: @auth_timeout} 
    end
  
    def self.authenticate?(username,password)
      (username == @username) && (password == @password) ? true : false
    end 

    def self.valid_token?(token)
      begin
        return false if token.nil?
        doc = {:database => Ragios::CouchdbAdmin.auth_session, :doc_id => token}
        auth = Couchdb.view doc, Ragios::CouchdbAdmin.session
        time_elapsed = (Time.now.to_f - Time.at(auth["timestamp"]).to_f).to_i
        time_elapsed > auth["timeout"] ? false : true
      rescue CouchdbException
        false
      end
    end
    
    def self.session
      auth_session_token = UUIDTools::UUID.random_create.to_s
      data = {:timeout => @auth_timeout, :timestamp => Time.now.to_i}
      doc = {:database => Ragios::CouchdbAdmin.auth_session, :doc_id => auth_session_token, :data => data}
      Couchdb.create_doc doc, Ragios::CouchdbAdmin.session
      auth_session_token
    end
  end
end
