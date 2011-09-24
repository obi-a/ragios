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
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

get '/monitors/:key/:value*' do
    key = params[:key].to_sym
    value = params[:value]
    monitors = Ragios::Server.find_monitors(key => value)
    m = Yajl::Encoder.encode(monitors)
    if m.to_s == '[]'
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
    Yajl::Encoder.encode({ "ok" => "true"})
  rescue 
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

delete '/delete/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.delete_monitor(id)
   if hash.to_s == "not_found"  
    status 404
    body  Yajl::Encoder.encode({error: 'not_found', check: 'monitor_id'})
   elsif hash.include?("id") && hash.include?("ok") 
    Yajl::Encoder.encode({ok:'true'})
   else
    status 500
    body  Yajl::Encoder.encode({error: 'unknown'})
  end
end

post '/stop/monitor/:id*' do
   id = params[:id]
   hash = Ragios::Server.stop_monitor(id)
   if hash.to_s == "not_found"  
    status 404
    body  Yajl::Encoder.encode({error: 'not_found', check: 'monitor_id'})
   elsif hash.include?("id") && hash.include?("ok") 
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
    body  Yajl::Encoder.encode({error: 'something went wrong', check: 'monitor_id'})
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
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end

end

post '/restart/status_update/:tag*' do
   tag = params[:tag]
   update = Ragios::Server.restart_status_updates(tag)
   if update == nil 
      status 404
      Yajl::Encoder.encode({ "Error" => "no stopped status update found for named tag"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
  end
end

post '/stop/status_update/:tag*' do
   tag = params[:tag]
   update = Ragios::Server.stop_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "Error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
   end
end

delete '/delete/status_update/:tag*' do
   tag = params[:tag]
   update = Ragios::Server.delete_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "Error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
   end
end

put '/edit/status_update/:id*' do
 begin
   data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   id = params[:id]
   update = Ragios::Server.edit_status_update(id,data)
   Yajl::Encoder.encode(hash)
   if update[0].include?("_id") 
       Yajl::Encoder.encode({ok:'true'})
   else
       status 500
        Yajl::Encoder.encode({error:'unknown'})
   end
  rescue CouchdbException => e
   if e.to_s == 'CouchDB: Error - not_found. Reason - missing'
     status 404
     Yajl::Encoder.encode({ "error" => e.error, check: 'status_update_id'})
   else
    raise
   end
  end
end

get '/*' do 
  status 400
  Yajl::Encoder.encode({ error: "bad_request"})
end

put '/*' do 
  status 400
  Yajl::Encoder.encode({ error: "bad_request"})
end

post '/*' do 
  status 400
  Yajl::Encoder.encode({ error: "bad_request"})
end

delete '/*' do 
  status 400
  Yajl::Encoder.encode({ error: "bad_request"})
end


