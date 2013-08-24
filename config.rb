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
amazon_account = { access_key: ENV['AMAZON_ACCESS_KEY'],
                   secret_key: ENV['AMAZON_SECRET_KEY'], 
                   send_from: ENV['AMAZON_ACCESS_SECRET'] }

Ragios::SESNotifier.config(amazon_account)


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






