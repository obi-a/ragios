#create database if it doesn't already exisit
Ragios::CouchdbAdmin.create_database

controller = Ragios::Controller
controller.scheduler(Ragios::Scheduler.new(controller))
controller.model(Ragios::Model::CouchdbMonitorModel)
controller.logger(Ragios::CouchdbLogger.new)

begin
  controller.restart_all
rescue Ragios::MonitorNotFound
end
