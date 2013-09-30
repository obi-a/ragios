#create database if it doesn't already exisit
Ragios::DatabaseAdmin.create_database

controller = Ragios::Controller
controller.scheduler(Ragios::Schedulers::Server.new)
controller.model(Ragios::Model::CouchdbModel)

begin
  controller.restart_monitors
rescue Ragios::MonitorNotFound
end
