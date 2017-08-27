module Ragios
  module Database
    class Admin
      attr_reader :database, :database_config

      def initialize
        @database_config = Ragios::DATABASE
        @database = Leanback::Couchdb.new(@database_config)
      end

      def setup_database
        begin
          @database.create
        rescue Leanback::CouchdbException => e
          unauthorized = (e.response[:error] == "unauthorized") rescue false
          raise e if unauthorized
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
end
