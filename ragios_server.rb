require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'
require dir + 'config'
require 'sinatra' 
require 'yajl'


get '/' do
 "Ragios Server"
end


put '/ragios/monitor' do

  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  Ragios::Monitor.start monitors

  "{\"ok\":true}"
end
