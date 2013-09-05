dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'

#Replace with Gmail username and password
gmail_account = {username: ENV['GMAIL_USERNAME'],
                 password: ENV['GMAIL_PASSWORD']} 

Ragios::GmailNotifier.config(gmail_account)

#replace with twitter credentials
twitter_cred = {consumer_key: ENV['TWITTER_CONSUMER_KEY'], 
               consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
                 access_token: ENV['TWITTER_ACCESS_TOKEN'],
                 access_secret: ENV['TWITTER_ACCESS_SECRET']}

Ragios::TwitterNotifier.config(twitter_cred)  

#Replace with amazon credientials for Amazon Simple Email Service Notifier
amazon_account = { access_key: ENV['AWS_ACCESS_KEY_ID'],
                   secret_key: ENV['AWS_SECRET_ACCESS_KEY'], 
                   send_from: "Ragios Alert <alerts@ragios.org>" }

Ragios::SESNotifier.config(amazon_account)

#log activity of monitors, set true to log activity
Ragios::Logger.config(log_activity = true)

ragios_admin_user = {username: ENV['RAGIOS_ADMIN_USERNAME'],
                     password: ENV['RAGIOS_ADMIN_PASSWORD'],
                     auth_timeout: ENV['RAGIOS_ADMIN_AUTH_TIMEOUT'].to_i} 

Ragios::Admin.config(ragios_admin_user)

#database configuration
database_admin = {login:     {username: ENV['COUCHDB_ADMIN_USERNAME'],
                              password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                  databases: { monitors: 'ragios_monitors',
                               status_updates_settings: 'status_update_settings',
                               activity_log: 'ragios_activity_log',
                               auth_session: 'ragios_auth_session'},
                  couchdb:  {bind_address: 'http://localhost',
                             port:'5984'}
                 } 

Ragios::DatabaseAdmin.config(database_admin)
