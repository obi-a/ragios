#initialization code for the console
options = {server_scheduler: Ragios::Schedulers::Server.new}
Ragios::Controller.init(options)
