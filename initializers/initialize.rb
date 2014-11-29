#create database if it doesn't already exisit
Ragios::CouchdbAdmin.setup_database
Ragios::Controller.start_all_active
