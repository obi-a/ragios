dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'

ragios_admin_user = {username: ENV['RAGIOS_ADMIN_USERNAME'],
                     password: ENV['RAGIOS_ADMIN_PASSWORD'],
                     authentication: true,
                     auth_timeout: 900}

Ragios::Admin.config(ragios_admin_user)

#database configuration
database_admin = {login: {username: ENV['COUCHDB_ADMIN_USERNAME'], password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                    database: 'ragios_database',
                    couchdb:  {address: 'http://localhost', port:'5984'}
                 }

Ragios::CouchdbAdmin.config(database_admin)
