module Ragios
  module Web
    class Admin
      attr_reader :database, :username, :password, :auth_timeout, :authentication

      def initialize
        @username = Ragios::ADMIN[:username]
        @password = Ragios::ADMIN[:password]
        @auth_timeout = Ragios::ADMIN[:auth_timeout]
        @authentication = (Ragios::ADMIN[:authentication] == "true") ? true : false
        @database = Ragios.database
      end

      def authenticate?(user, pass)
        (user == @username) && (pass == @password)
      end

      def authentication?
        @authentication
      end

      def valid_token?(token)
        return true unless authentication
        return false if token.blank?
        auth_session = @database.get_doc(token)
        time_elapsed = (Time.now.to_f - Time.at(auth_session[:timestamp]).to_f).to_i
        is_valid_token =
          if auth_session[:auth_timeout].to_i > time_elapsed
            true
          else
            @database.delete_doc!(token)
            false
          end
      rescue Leanback::CouchdbException
        false
      end

      def invalidate_token(token)
        return false if token.blank?
        database.delete_doc!(token)
      rescue Leanback::CouchdbException
        false
      end

      def session
        auth_session_token = SecureRandom.uuid
        @database.create_doc(
          auth_session_token,
          auth_timeout: @auth_timeout,
          timestamp: Time.now.to_i,
          type: "auth_session",
          created_at: Time.now
        )
        return auth_session_token
      end
    end
  end
end
