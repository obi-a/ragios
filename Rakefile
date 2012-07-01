 task :create_db_admin do
    require 'leanback'
    hash = Couchdb.login("current_admin_username","current_admin_password") 
    auth_session =  hash["AuthSession"]

    data = {:section => "admins",
              :key => "ragios_server",
                :value => "ragios"}
    Couchdb.set_config data,auth_session
 end

task :spec do
  sh 'rspec spec/'
end

task :notifiers do
  sh 'rspec spec/notifiers'
end

task :plugins do
  sh 'rspec -fs spec/plugins'
end

task :core do
  sh 'rspec -fs spec/ragios'
end

task :server do
  sh 'rspec -fs spec/server'
end

task :test_notifiers => :notifiers
task :test_plugins => :plugins
task :test_core => :core
task :test_server => :server

task :test => :server
task :default => :server

