#initialization code for the console
Ragios::Controller.scheduler(Ragios::Scheduler.new(Ragios::Controller))
Ragios::Controller.model(Ragios::Model::CouchdbMonitorModel)
Ragios::Controller.logger(Ragios::CouchdbLogger.new)
