module Ragios
  class DatabaseAdmin
    def self.config(database_config)
     @@username = database_config[:login][:username]
     @@password = database_config[:login][:password]
     @@monitors = database_config[:databases][:monitors]
     @@status_updates_settings = database_config[:databases][:status_updates_settings]
     @@activity_log = database_config[:databases][:activity_log]
     @@auth_session = database_config[:databases][:auth_session]
     Couchdb.address = database_config[:couchdb][:bind_address]
     Couchdb.port = database_config[:couchdb][:port]
    end

    def self.monitors
      @@monitors
    end
   
    def self.status_updates_settings
      @@status_updates_settings
    end

    def self.activity_log
      @@activity_log
    end

    def self.auth_session
      @@auth_session
    end
   
    def self.admin
       database_admin = {username: @@username,
                 password: @@password} 
    end
    
    def self.session
      hash = Couchdb.login(@@username,@@password) 
      hash["AuthSession"]
    end
  end
end
