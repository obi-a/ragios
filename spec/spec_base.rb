require 'rubygems'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
require 'celluloid/test'
#Ragios::Logging.logger.level = :warn

module Ragios
  SERVERS = {
    recurring_jobs_receiver: "inproc://recurring_jobs_receiver",
    workers_pusher: "inproc://workers_pusher",
    notifications_receiver: "inproc://notifications_receiver",
    events_subscriber: "inproc://events_subscriber"
  }
end
