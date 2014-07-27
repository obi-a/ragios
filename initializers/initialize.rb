#create database if it doesn't already exisit
Ragios::CouchdbAdmin.setup_database
Ragios::Controller.restart_all_active
