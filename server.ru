#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'config'
require dir + 'lib/ragios/rest_server'

run Sinatra::Application

auth_session = Ragios::DatabaseAdmin.session
database_admin = Ragios::DatabaseAdmin.admin



#create the database if they don't already exist
begin
 Couchdb.create 'monitors',auth_session
 data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
                  }
#ADD SPECs to ensure this
Couchdb.set_security('monitors',data,auth_session)
rescue CouchdbException 
end

begin
 Couchdb.create 'status_update_settings',auth_session
 data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
                  }
 #TO BE ENABLED AFTER Proper testing
 #Couchdb.set_security('status_update_settings',data,auth_session)
rescue CouchdbException 
end



Ragios::Server.init

#restart monitors from the database
begin
Ragios::Monitor.restart
rescue RuntimeError
end

#run schedule any available status updates
begin
Ragios::Server.restart_status_updates
rescue RuntimeError
end
