module Ragios
  class CouchdbAdmin
    def self.config(database_config)
      @database_config = database_config
      @database = Leanback::Couchdb.new(@database_config)
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

      if @database_config[:username]
        security_settings = {
          admins: {"names" => [@database_config[:username]], "roles" => ["admin"]},
          readers: {"names" => [@database_config[:username]],"roles"  => ["admin"]}
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
