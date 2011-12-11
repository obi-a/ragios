module Ragios
  class DatabaseAdmin
    attr_accessor :username
    attr_accessor :password
    def self.config(database_admin)
     @@username = database_admin[:username]
     @@password = database_admin[:password]
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
