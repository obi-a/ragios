module Ragios
  class Admin
    attr_accessor :username
    attr_accessor :password
    attr_accessor :auth_timeout

    def self.config(ragios_admin)
     @@username = ragios_admin[:username]
     @@password = ragios_admin[:password]
     @@auth_timeout = ragios_admin[:auth_timeout]
    end

    def self.admin
       admin = {username: @@username,
                 password: @@password,
                  auth_timeout: @@auth_timeout} 
    end
  
    def self.authenticate?(username,password)
      true if (username == @@username) && (password == @@password)
    end 

    def self.valid_key?(key)
      begin
        return false if key.nil?
        doc = {:database => 'ragios_auth_session', :doc_id => key}
        auth = Couchdb.view doc, Ragios::DatabaseAdmin.session
        time_elapsed = (Time.now.to_f - Time.at(auth["timestamp"]).to_f).to_i
        if (time_elapsed > auth["timeout"])
          false
        else
          true
        end
      rescue CouchdbException
        false
      end
    end
    
    def self.session
      auth_session_key = UUIDTools::UUID.random_create.to_s
      data = {:timeout => @@auth_timeout, :timestamp => Time.now.to_i}
      doc = {:database => 'ragios_auth_session', :doc_id => auth_session_key, :data => data}
      Couchdb.create_doc doc, Ragios::DatabaseAdmin.session
      auth_session_key
    end
  end
end
