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

put  '/update/monitor/:id*' do
    data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
    id = params[:id]
    hash = Ragios::Server.update_monitor(id,data)
    Yajl::Encoder.encode(hash)
end

delete '/delete/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.delete_monitor(id)
   Yajl::Encoder.encode(hash)
end

post '/stop/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.stop_monitor(id)
   Yajl::Encoder.encode(hash)
end

post '/restart/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.restart_monitor(id)
   Yajl::Encoder.encode(hash)
end

get '/monitor/id/:id*' do
   id = params[:id]
   monitor = Ragios::Server.get_monitor(id)
   Yajl::Encoder.encode(monitor)
end

get '/monitors*' do
 monitors =  Ragios::Server.get_all_monitors
 Yajl::Encoder.encode(monitors)
end

#status updates
post '/start/status_update*' do
   config = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   hash = Ragios::Server.start_status_update(config)
   Yajl::Encoder.encode(hash)
end

post '/restart/status_update/:tag*' do
   tag = params[:tag]
   hash = Ragios::Server.restart_status_updates(tag)
   Yajl::Encoder.encode(hash)
end

post '/stop/status_update/:tag*' do
   tag = params[:tag]
   hash = Ragios::Server.stop_status_update(tag)
   Yajl::Encoder.encode(hash)
end

delete '/delete/status_update/:tag*' do
   tag = params[:tag]
   hash = Ragios::Server.delete_status_update(tag)
   Yajl::Encoder.encode(hash)
end

put '/edit/status_update/:id*' do
   data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   id = params[:id]
   hash = Ragios::Server.edit_status_update(id,data)
   Yajl::Encoder.encode(hash)
end

not_found do
     Yajl::Encoder.encode({error:"not found"})
end
