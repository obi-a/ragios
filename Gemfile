source 'http://rubygems.org'

gem 'rufus-scheduler', '~> 3.4.2', :require => 'rufus/scheduler'
gem 'state_machine', '~> 1.2.0'
gem 'leanback', '~> 0.5.14'
gem 'contracts', '0.4'
gem 'celluloid-zmq', '~> 0.17.2'
gem "nokogiri", '~> 1.10.4'

gem 'daemons', :group => [:services]
gem 'rake', :group => [:development, :test]
gem 'ffi', '~> 1.9.24'
gem 'rack', '~> 2.0.6', :group => [:development, :web]

group :development do
  gem 'pry'
  gem 'foreman'
end

group :notifiers do
  gem 'aws-ses'
end

group :plugins do
  gem 'excon', '~> 0.71.0'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end

group :web, :development do
  gem 'puma', '~> 3.12.4'
  gem 'sinatra', '~> 2.0.2', :require => 'sinatra/base'
  gem 'rack-protection', '~> 2.0.0'
end
