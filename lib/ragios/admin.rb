module Ragios
  class Admin
    attr_accessor :username
    attr_accessor :password
    attr_accessor :auth_timeout

    def self.config(ragios_admin)
      @username = ragios_admin[:username]
      @password = ragios_admin[:password]
      @auth_timeout = ragios_admin[:auth_timeout]
      @database = Ragios::CouchdbAdmin.get_database
    end
=begin
    def self.admin
      {username: @username,
       password: @password,
       auth_timeout: @auth_timeout}
    end
=end
    def self.authenticate?(username,password)
      (username == @username) && (password == @password)
    end

    def self.valid_token?(token)
      return false if token.blank?
      auth_session = @database.get_doc(token)
      time_elapsed = (Time.now.to_f - Time.at(auth_session[:timestamp]).to_f).to_i
      is_valid_token =
      if auth_session[:timeout] > time_elapsed
        true
      else
        @database.delete_doc(token)
        false
      end
    rescue CouchdbException
      false
    end
    def self.session
      auth_session_token = UUIDTools::UUID.random_create.to_s
      @database.create_doc(auth_session_token,
                            timeout: @auth_timeout,
                            timestamp: Time.now.to_i,
                            type: auth_session)
      return auth_session_token
    end
  end
end
