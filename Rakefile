 task :create_db_admin do
    require 'leanback'
    hash = Couchdb.login("current_admin_username","current_admin_password") 
    auth_session =  hash["AuthSession"]

    data = {:section => "admins",
              :key => "ragios_server",
                :value => "ragios"}
    Couchdb.set_config data,auth_session
 end

task :console do 
  ragios_file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Ragios/config'))
  irb = "bundle exec pry -r #{ragios_file}"
  sh irb 
end


task :server_console do 
  ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Ragios'))
  config = ragios_dir + '/config'
  initialize = ragios_dir + '/initialize'
  irb = "bundle exec pry -r #{config} -r #{initialize}"
  sh irb 
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

task :s => :server_console
task :c => :console
task :test_notifiers => :notifiers
task :test_plugins => :plugins
task :test_core => :core
task :test_server => :server

task :test => :server
task :default => :server
