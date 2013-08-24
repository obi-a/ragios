database_admin = {username: ENV['COUCHDB_ADMIN_USERNAME'],
                 password: ENV['COUCHDB_ADMIN_PASSWORD']} 

Ragios::DatabaseAdmin.config(database_admin)

#log activity of monitors, set true to log activity
log_activity = true
Ragios::Logger.config(log_activity)

ragios_admin_user = {username: ENV['RAGIOS_ADMIN_USERNAME'],
                     password: ENV['RAGIOS_ADMIN_PASSWORD'],
                     auth_timeout: ENV['RAGIOS_ADMIN_AUTH_TIMEOUT'].to_i}

Ragios::Admin.config(ragios_admin_user)






