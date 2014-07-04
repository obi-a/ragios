#create database if it doesn't already exisit
Ragios::CouchdbAdmin.create_database
Ragios::Controller.restart_all
