#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'config'
require dir + 'lib/ragios/rest_server'

run Sinatra::Application

auth_session = Ragios::DatabaseAdmin.session

#create the database if they don't already exist
begin
 Couchdb.create 'monitors',auth_session
rescue CouchdbException 
end

begin
 Couchdb.create 'status_update_settings',auth_session
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
