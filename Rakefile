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
  ragios_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Ragios'))
  config = ragios_dir + '/config'
  console = ragios_dir + '/initializers/console'
  irb = "bundle exec pry -r #{config}  -r #{console}"
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

task :unit do
  sh 'rspec -fs spec/unit_tests'
end

task :integration do
  sh 'rspec -fs spec/integration'
end

task :c => :console
task :test_notifiers => :notifiers
task :test_plugins => :plugins
task :test_unit => :unit
task :test_integration => :integration

task :test => :integration
task :default => :integration