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
Couchdb.set_security('monitors',data,auth_session)
rescue CouchdbException  => e
 #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
  
end

begin
 Couchdb.create 'status_update_settings',auth_session
 data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
                  }
 Couchdb.set_security('status_update_settings',data,auth_session)
rescue CouchdbException 
   #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
end


1
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
