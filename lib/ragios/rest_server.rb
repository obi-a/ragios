#require 'rubygems'
#require "bundler/setup"
#dir = Pathname(__FILE__).dirname.expand_path
#require dir + 'lib/ragios'
#require dir + 'config'
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

#adds monitors to the system and starts monitoring them
put '/monitors' do
 begin
  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  Ragios::Monitor.start monitors,server=TRUE
  Yajl::Encoder.encode({ok:"true"})
 rescue 
  status 500
  body  Yajl::Encoder.encode({error: $!.to_s})
 end
end

get '/monitors/:key/:value*' do
    key = params[:key].to_sym
    value = params[:value]
    monitors = Ragios::Server.find_monitors(key => value)
    m = Yajl::Encoder.encode(monitors)
    if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ error: "not_found"})
    else 
      m
    end
end

put  '/update/monitor/:id*' do
  begin
    data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
    id = params[:id]
    hash = Ragios::Server.update_monitor(id,data)
    Yajl::Encoder.encode(hash)
    Yajl::Encoder.encode({ "ok" => "true"})
  rescue 
  status 500
  body  Yajl::Encoder.encode({error: $!.to_s})
 end
end

delete '/delete/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.delete_monitor(id)
   m = Yajl::Encoder.encode(hash)
   
   if m.to_s == '"not_found"'  
    status 404
    body  Yajl::Encoder.encode({error: 'not_found', check: 'monitor_id'})
   elsif m.include?("id") && m.include?("ok") 
    Yajl::Encoder.encode({ok:'true'})
   else
    status 500
    body  Yajl::Encoder.encode({error: 'unknown'})
  end
end

post '/stop/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.stop_monitor(id)
   m = Yajl::Encoder.encode(hash) 

   if m.to_s == '"not_found"'  
    status 404
    body  Yajl::Encoder.encode({error: 'not_found', check: 'monitor_id'})
   elsif m.include?("id") && m.include?("ok") 
    Yajl::Encoder.encode({ok:'true'})
   else
    status 500
    body  Yajl::Encoder.encode({error: 'unknown'})
  end
end

post '/restart/monitor/:id*' do
  begin 
   id = params[:id]
   Ragios::Server.restart_monitor(id)
   Yajl::Encoder.encode({ok: 'true'})
   rescue 
    status 500
    body  Yajl::Encoder.encode({error: $!.to_s, check: 'monitor_id'})
    end
end

get '/monitor/id/:id*' do
  begin
   id = params[:id]
   monitor = Ragios::Server.get_monitor(id)
   Yajl::Encoder.encode(monitor) 
 rescue CouchdbException => e
   if e.to_s == 'CouchDB: Error - not_found. Reason - missing'
     status 404
     Yajl::Encoder.encode({ "error" => e.error, check: 'monitor_id'})
   else
    raise
   end
 end 
end

get '/monitors*' do
  monitors =  Ragios::Server.get_all_monitors
  m = Yajl::Encoder.encode(monitors)
  if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ "Error" => "not_found"})
  else 
    m
  end
end

#status updates
get '/status_update/:key/:value*' do
 key = params[:key].to_sym
 value = params[:value]
 monitors = Ragios::Server.find_status_update(key => value)
 m = Yajl::Encoder.encode(monitors) 
 if m.to_s == '[]'
  status 404
  Yajl::Encoder.encode({ "Error" => "not_found"})
 else 
   m
 end
end

post '/start/status_update*' do
  begin
   config = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   hash = Ragios::Server.start_status_update(config)
   Yajl::Encoder.encode(hash)
  rescue 
  status 500
  body  Yajl::Encoder.encode({error: $!.to_s})
 end

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
     status 404
     Yajl::Encoder.encode({error:"not found"})
end
