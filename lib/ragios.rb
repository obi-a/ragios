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

module Ragios
  ADMIN = {
    username: ENV['RAGIOS_ADMIN_USERNAME'],
    password: ENV['RAGIOS_ADMIN_PASSWORD'],
    authentication: ENV['RAGIOS_AUTHENTICATION'] || false,
    auth_timeout: ENV['RAGIOS_AUTH_TIMEOUT'] || 900
  }

  DATABASE = {
    username: ENV['COUCHDB_ADMIN_USERNAME'],
    password: ENV['COUCHDB_ADMIN_PASSWORD'],
    database: ENV['RAGIOS_DATABASE'] || 'ragios_database',
    address: ENV['RAGIOS_COUCHDB_ADDRESS'] || 'http://localhost',
    port: ENV['RAGIOS_COUCHDB_PORT'] || '5984'
  }

  SERVERS = {
    recurring_jobs_receiver: ENV['RAGIOS_RECURRING_JOBS_RECEIVER'] || "tcp://127.0.0.1:5042",
    workers_pusher: ENV['RAGIOS_WORKERS_PUSHER'] || "tcp://127.0.0.1:5043",
    notifications_receiver: ENV['RAGIOS_NOTIFICATIONS_RECEIVER'] || "tcp://127.0.0.1:5044",
    events_subscriber: ENV['RAGIOS_EVENTS_SUBSCRIBER'] || "tcp://127.0.0.1:5045"
  }

  LOGGER = {
    level: ENV['RAGIOS_LOG_LEVEL'] || :info,
    program_name: "Ragios"
  }

  class << self
    def database
      @database ||= db_admin.database
    end

    def db_admin
      @db_admin ||= Ragios::Database::Admin.new
    end

    def admin
      @admin ||= Ragios::Web::Admin.new
    end

    def logger
      ::Ragios::Logging.logger
    end

    def log_event(performer, action, event, level = :info)
      if event.is_a?(Hash) && event[:monitor_id] && event[:event_type]
        Ragios.logger.send(level, "#{performer.class.name} #{action} event #{event[:event_type]} for monitor_id: #{event[:monitor_id]} with options #{event}")
      else
        Ragios.logger.send(level, "#{performer.class.name} #{action} event #{event}")
      end
    end
  end
end

# extracted from activesupport
class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
end

Ragios.db_admin.setup_database
# TODO: may remove initializers entirely, similar configure them notifiers or plugins with env vars
require_all '/initializers'
