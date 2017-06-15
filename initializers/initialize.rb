#create database if it doesn't already exisit
Ragios::Database::Admin.setup_database

# TODO remove later
# this functionality should be moved to a rake task
#Ragios::Controller.start_all_active
