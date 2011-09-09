task :spec do
  sh 'rspec spec/'
end

task :plugins do
  sh 'rspec spec/plugins'
end

task :core do
  sh 'rspec spec/ragios'
end

task :server do
  sh 'rspec spec/server'
end

task :test_plugins => :plugins
task :test_core => :core
task :test_server => :server

task :test => :server
task :default => :server

