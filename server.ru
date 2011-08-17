#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'config'
require dir + 'lib/ragios/rest_server'

run Sinatra::Application

Ragios::Server.init

#restart monitors from the database
Ragios::Monitor.restart

#run schedule any available status updates
Ragios::Server.restart_status_updates
