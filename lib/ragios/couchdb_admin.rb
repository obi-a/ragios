module Ragios
  class CouchdbAdmin
    def self.config(database_config)
      @database_config = database_config
      @database = Leanback::Couchdb.new(
        database: @database_config[:database],
        username: @database_config[:login][:username],
        password: @database_config[:login][:password],
        address: @database_config[:couchdb][:address],
        port: @database_config[:couchdb][:port])
    end
    def self.get_database
      @database
    end
    def self.setup_database
      begin
        @database.create
      rescue Leanback::CouchdbException => e
        raise e if e.response[:error] == "unauthorized"
      end

      if [@database_config[:login][:username], @database_config[:login][:username]].all?
        security_settings = {:admins => {"names" => [@database_config[:login][:username]], "roles" => ["admin"]},
                                :readers => {"names" => [@database_config[:login][:username]],"roles"  => ["admin"]}
                             }
        begin
          @database.security_object = security_settings
        rescue Leanback::CouchdbException
        end
      end
      true
    end
  end
end
