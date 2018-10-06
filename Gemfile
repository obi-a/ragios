source 'http://rubygems.org'

gem 'rufus-scheduler', '~> 3.4.2', :require => 'rufus/scheduler'
gem 'state_machine'
gem 'leanback', '~> 0.5.8'
gem 'contracts'
gem 'celluloid-zmq', '~> 0.17.2'

gem 'daemons', :group => [:services]
gem 'rake', :group => [:development, :test]
gem 'ffi', '~> 1.9.24'

group :development do
  gem 'pry'
  gem 'foreman'
  gem 'ragios-client', '~> 0.2.1'
end

group :notifiers do
  gem 'aws-ses'
end

group :plugins do
  gem 'excon'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end

group :web, :development do
  gem 'puma', '~> 3.10.0'
  gem 'sinatra', '~> 2.0.2', :require => 'sinatra/base'
  gem 'rack-protection', '~> 2.0.0'
end
