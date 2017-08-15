require 'rubygems'
require 'bundler/setup'
require 'net/http'
require 'net/https'

require "celluloid/zmq/current"
require 'celluloid/current'

Celluloid::ZMQ.init

Bundler.require

dir = Pathname(__FILE__).dirname.expand_path + 'ragios/'

def require_all(path)
 Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file|
   require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
 end
end

#system
require_all '/ragios'
require_all '/ragios/ZMQ'

#notifiers
require_all '/ragios/notifiers/email'
require_all '/ragios/notifiers'
require_all '/ragios/monitors'
require_all '/ragios/monitors/workers'
require_all '/ragios/database'
require_all '/ragios/recurring_jobs'
require_all '/ragios/web'
require_all '/ragios/events'
require_all '/ragios/notifications'


require_all '/ragios/plugins'



#TODO: move this to notifications service
#global variable path to the folder with erb message files
$path_to_messages =  File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios/messages/'))

ragios_admin_user = {
  username: ENV['RAGIOS_ADMIN_USERNAME'],
  password: ENV['RAGIOS_ADMIN_PASSWORD'],
  authentication: ENV['RAGIOS_AUTHENTICATION'] || false ,
  auth_timeout: ENV['RAGIOS_AUTH_TIMEOUT'] || 900
}

Ragios::Web::Admin.config(ragios_admin_user)

#database configuration
database_admin = {
  username: ENV['COUCHDB_ADMIN_USERNAME'],
  password: ENV['COUCHDB_ADMIN_PASSWORD'],
  database: ENV['RAGIOS_DATABASE'] || 'ragios_database',
  address: ENV['RAGIOS_COUCHDB_ADDRESS'] || 'http://localhost',
  port: ENV['RAGIOS_COUCHDB_PORT'] || '5984'
}
Ragios::Database::Admin.config(database_admin)
