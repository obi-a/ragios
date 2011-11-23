#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'config'
require dir + 'lib/ragios/rest_server'

run Sinatra::Application

#create the database if they don't already exist
begin
 Couchdb.create 'monitors'
rescue CouchdbException 
end

begin
 Couchdb.create 'status_update_settings'
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
