module Ragios
  class CouchdbAdmin
    def self.config(database_config)
      @database_config = database_config
      @database = Leanback::Couchdb.new(database: @database_config[:database],
                      username: @database_config[:login][:username],
                      password: @database_config[:login][:password],
                      address: @database_config[:couchdb][:address],
                      port: @database_config[:couchdb][:port])
    end
    def self.setup_database

    end
    def self.get_database
      @database
    end
=begin
    def self.config(database_config)
     @username = database_config[:login][:username]
     @password = database_config[:login][:password]
     @monitors = database_config[:databases][:monitors]
     @activity_log = database_config[:databases][:activity_log]
     @auth_session = database_config[:databases][:auth_session]
     Couchdb.address = database_config[:couchdb][:address]
     Couchdb.port = database_config[:couchdb][:port]
    end
    def self.monitors
      @monitors
    end


    def self.activity_log
      @activity_log
    end

    def self.auth_session
      @auth_session
    end

    def self.admin
      {username: @username, password: @password}
    end

    def self.session
      hash = Couchdb.login(@username,@password)
      hash["AuthSession"]
    end

    #TODO: refactor this code

    def self.create_database
      #create the database if they don't already exist
        database_admin = {username: @username,
                            password: @password}
        Couchdb.create monitors,session
        data = {:admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                  :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
               }
        Couchdb.set_security(monitors,data,session)
        Couchdb.create activity_log,session
        data = {:admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                  :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}}
        Couchdb.set_security(activity_log,data,session)
        Couchdb.create(auth_session, session)
        data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}}
        Couchdb.set_security(auth_session,data,session)
      rescue CouchdbException  => e
        #raise error unless the database have already been creates
        raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
    end
=end
  end
end
