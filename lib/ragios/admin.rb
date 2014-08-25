module Ragios
  class Admin
    attr_accessor :username
    attr_accessor :password
    attr_accessor :auth_timeout

    def self.config(ragios_admin)
      @username = ragios_admin[:username]
      @password = ragios_admin[:password]
      @auth_timeout = ragios_admin[:auth_timeout]
      @authentication = ragios_admin[:authentication]
      @database = Ragios::CouchdbAdmin.get_database
    end

    def self.authenticate?(username,password)
      (username == @username) && (password == @password)
    end

    def self.database
      @database ||= Ragios::CouchdbAdmin.get_database
    end

    def self.valid_token?(token)
      return true unless @authentication
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

    def self.invalidate_token(token)
      @database.delete_doc!(token)
    rescue Leanback::CouchdbException
      false
    end

    def self.session
      auth_session_token = UUIDTools::UUID.random_create.to_s
      database.create_doc(
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
