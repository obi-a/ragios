dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'

#Replace with Gmail username and password
gmail_account = {username: ENV['GMAIL_USERNAME'],
                 password: ENV['GMAIL_PASSWORD']}

Ragios::Notifier::GmailNotifier.config(gmail_account)

#replace with twitter credentials
twitter_cred = {consumer_key: ENV['TWITTER_CONSUMER_KEY'],
               consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
                 access_token: ENV['TWITTER_ACCESS_TOKEN'],
                 access_secret: ENV['TWITTER_ACCESS_SECRET']}

Ragios::Notifier::TwitterNotifier.config(twitter_cred)

#Replace with amazon credientials for Amazon Simple Email Service Notifier
amazon_account = { access_key: ENV['AWS_ACCESS_KEY_ID'],
                   secret_key: ENV['AWS_SECRET_ACCESS_KEY'],
                   send_from: ENV['AWS_SES_SEND_FROM']}

Ragios::Notifier::Ses.config(amazon_account)

ragios_admin_user = {username: ENV['RAGIOS_ADMIN_USERNAME'],
                     password: ENV['RAGIOS_ADMIN_PASSWORD'],
                     auth_timeout: 900}

Ragios::Admin.config(ragios_admin_user)

#database configuration
database_admin = {login: {username: ENV['COUCHDB_ADMIN_USERNAME'], password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                    database: 'ragios_database',
                    couchdb:  {address: 'http://localhost', port:'5984'}
                 }

Ragios::CouchdbAdmin.config(database_admin)
