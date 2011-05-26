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

  json_style_hash = Yajl::Parser.parse(request.body.read)
#will clean up the code later, still buggy
  new_hash = {}
  monitors = []
  count = 0

  json_style_hash.each do|hash|
      hash.each do |key,value|
        key = key.to_sym
        new_hash[key] = value
      end

   monitors[count] =  new_hash
   count += 1
  end
  Ragios::Monitor.start monitors 

   puts monitors.inspect 
  "{\"ok\":true}"
end
