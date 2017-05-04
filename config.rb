dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'

ragios_admin_user = {
  username: ENV['RAGIOS_ADMIN_USERNAME'],
  password: ENV['RAGIOS_ADMIN_PASSWORD'],
  authentication: ENV['RAGIOS_AUTHENTICATION'] || false ,
  auth_timeout: ENV['RAGIOS_AUTH_TIMEOUT'] || 900
}

Ragios::Admin.config(ragios_admin_user)

#database configuration
database_admin = {
  username: ENV['COUCHDB_ADMIN_USERNAME'],
  password: ENV['COUCHDB_ADMIN_PASSWORD'],
  database: ENV['RAGIOS_DATABASE'] || 'ragios_database',
  address: ENV['RAGIOS_COUCHDB_ADDRESS'] || 'http://localhost',
  port: ENV['RAGIOS_COUCHDB_PORT'] || '5984'
}
Ragios::CouchdbAdmin.config(database_admin)
