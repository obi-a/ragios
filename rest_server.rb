#require 'rubygems'
#require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'
require dir + 'config'
require 'sinatra' 
require 'yajl'

#using config.yml with thin instead
#configure do
#    set :bind, 'localhost'
#    set :port, '5041'
#    set :server, %w[thin mongrel webrick]
    
# end


get '/' do
  Yajl::Encoder.encode({ "Ragios Server" => "welcome"})
end

put '/monitors' do
 begin
  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  Ragios::Monitor.start monitors,server=TRUE
  Yajl::Encoder.encode({ok:"true"})
 rescue 
    Yajl::Encoder.encode({error: $!.to_s})
 end
end

get '/monitors/:key/:value*' do
    key = params[:key].to_sym
    value = params[:value]
    monitors = Ragios::Server.find_monitors(key => value)
    Yajl::Encoder.encode(monitors)
end

get '/stats/:key/:value*' do
    key = params[:key].to_sym
    value = params[:value]
    monitors = Ragios::Server.find_stats(key => value)
    Yajl::Encoder.encode(monitors)
end

get '/monitors/all*' do
 monitors =  Ragios::Server.get_monitors
 Yajl::Encoder.encode(monitors)
end

get '/stats/all*' do
 monitors = Ragios::Server.get_stats
 Yajl::Encoder.encode(monitors)
end

not_found do
     Yajl::Encoder.encode({error:"not found"})
end
