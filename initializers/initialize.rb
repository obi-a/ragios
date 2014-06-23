#create database if it doesn't already exisit
Ragios::CouchdbAdmin.create_database
Ragios::Controller.restart_all
=begin
controller = Ragios::Controller
controller.scheduler(Ragios::Scheduler.new(controller))
controller.model(Ragios::Model::CouchdbMonitorModel)
controller.logger(Ragios::CouchdbLogger.new)
controller.restart_all
=end
