require 'rubygems'
require 'bundler/setup'
#require 'net/http'
#require 'net/https'

require "celluloid/zmq/current"
require 'celluloid/current'

Celluloid::ZMQ.init

environment = ENV['RAGIOS_ENV'] || "development"

Bundler.require(:default, environment)

def require_all(path)
 Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file|
   require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
 end
end

dir = Pathname(__FILE__).dirname.expand_path + 'ragios/'

#system
require_all '/ragios'
require "#{dir}ZMQ/base"
require_all '/ragios/ZMQ'

#notifiers
require_all '/ragios/notifiers/email'
require_all '/ragios/notifiers'
require_all '/ragios/monitors'
require_all '/ragios/monitors/workers'
require_all '/ragios/database'
require_all '/ragios/recurring_jobs'
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

  recurring_jobs_receiver = if ENV['RAGIOS_RECURRING_JOBS_RECEIVER']
    ENV['RAGIOS_RECURRING_JOBS_RECEIVER']
  else
    recurring_jobs_receiver_address = ENV['RAGIOS_RECURRING_JOBS_RECEIVER_ADDRESS'] || "127.0.0.1"
    recurring_jobs_receiver_port = ENV['RAGIOS_RECURRING_JOBS_RECEIVER_PORT'] || "5042"
    "tcp://#{recurring_jobs_receiver_address}:#{recurring_jobs_receiver_port}"
  end

  workers_pusher = if ENV['RAGIOS_WORKERS_PUSHER']
    ENV['RAGIOS_WORKERS_PUSHER']
  else
    workers_pusher_address = ENV['RAGIOS_WORKERS_PUSHER_ADDRESS'] || "127.0.0.1"
    workers_pusher_port = ENV['RAGIOS_WORKERS_PUSHER_PORT'] || "5043"
    "tcp://#{workers_pusher_address}:#{workers_pusher_port}"
  end

  notifications_receiver = if ENV['RAGIOS_NOTIFICATIONS_RECEIVER']
    ENV['RAGIOS_NOTIFICATIONS_RECEIVER']
  else
    notifications_receiver_address = ENV['RAGIOS_NOTIFICATIONS_RECEIVER_ADDRESS'] || "127.0.0.1"
    notifications_receiver_port = ENV['RAGIOS_NOTIFICATIONS_RECEIVER_PORT'] || "5044"
    "tcp://#{notifications_receiver_address}:#{notifications_receiver_port}"
  end

  events_receiver = if ENV['RAGIOS_EVENTS_RECEIVER']
    ENV['RAGIOS_EVENTS_RECEIVER']
  else
    events_receiver_address = ENV['RAGIOS_EVENTS_RECEIVER_ADDRESS'] || "127.0.0.1"
    events_receiver_port = ENV['RAGIOS_EVENTS_RECEIVER_PORT'] || "5045"
    "tcp://#{events_receiver_address}:#{events_receiver_port}"
  end

  SERVERS = {
    recurring_jobs_receiver: recurring_jobs_receiver,
    workers_pusher: workers_pusher,
    notifications_receiver: notifications_receiver,
    events_receiver: events_receiver
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

    def retriable(options = {})
      opts = {on: Exception, tries: 1, interval: 1}.merge(options)

      exceptions = opts[:on].is_a?(Array) ? opts[:on] : [opts[:on]]
      retries    = opts[:tries]
      interval   = opts[:interval]
      tries      = 1

      begin
        return yield(tries)
      rescue *exceptions => e
        tries += 1

        if tries <= retries
          sleep interval
          retry
        else
          raise
        end
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


Ragios.retriable(on: Errno::ECONNREFUSED, interval: 3, tries: 5) do |try|
  Ragios.logger.info "Trying to connect to database attempt #{try}"
  Ragios.db_admin.setup_database
end
