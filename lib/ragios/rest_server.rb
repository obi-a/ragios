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

#TODO set Content-Type and other header attributes for each request
get '/' do
  Yajl::Encoder.encode({ "Ragios Server" => "welcome"})
end

#adds monitors to the system and starts monitoring them
post '/monitors*' do
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
     status 404
     Yajl::Encoder.encode({ error: "not_found"})
    else 
      m
    end
end

delete '/monitors/:id*' do
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

#stop a running monitor
put '/monitors/:id/state/stopped*' do
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

#restart a running monitor
put '/monitors/:id/state/active*' do
  begin 
   id = params[:id]
    m = Ragios::Server.restart_monitor(id)
   if m[0].class == Ragios::GenericMonitor
    Yajl::Encoder.encode({ok: 'true'})
   end
  rescue => e
   if e.to_s == "monitor not found"
    status 404
    body  Yajl::Encoder.encode({error: e.to_s}) 
   else
    status 500
    body  Yajl::Encoder.encode({error: e.to_s})
   end
  end
end

#edit an already existing monitor
put  '/monitors/:id*' do
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

get '/scheduler/monitors/:id*' do
  begin
     id = params[:id]
     sch = Ragios::Server.get_monitors_frm_scheduler(id)
     sch.inspect
  rescue CouchdbException => e
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/scheduler/monitors*' do
  begin
     sch = Ragios::Server.get_monitors_frm_scheduler
     sch.inspect
  rescue CouchdbException => e
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/monitors/:id*' do
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
     Yajl::Encoder.encode({ "error" => "not_found"})
  else 
    m
  end
end

#status updates
get '/status_updates/:key/:value*' do
 key = params[:key].to_sym
 value = params[:value]
 monitors = Ragios::Server.find_status_update(key => value)
 m = Yajl::Encoder.encode(monitors) 
 if m.to_s == '[]'
  status 404
  Yajl::Encoder.encode({ "error" => "not_found"})
 else 
   m
 end
end

post '/status_updates*' do
  begin
   config = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   hash = Ragios::Server.start_status_update(config)
   Yajl::Encoder.encode({ok:"true"})
  rescue 
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end

end

#restart a status update
put '/status_updates/:tag/state/active*' do
   tag = params[:tag]
   update = Ragios::Server.restart_status_updates(tag)
   if update == nil 
      status 404
      Yajl::Encoder.encode({ "error" => "no stopped status update found for named tag"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
  end
end

#stop a status update
put '/status_updates/:tag/state/stopped*' do
   tag = params[:tag]
   update = Ragios::Server.stop_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
   end
end

get '/scheduler/status_updates/:tag*' do
  begin
     tag = params[:tag]
     sch = Ragios::Server.get_status_update_frm_scheduler(tag)
     sch.inspect
  rescue CouchdbException => e
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/scheduler/status_updates*' do
  begin
     sch = Ragios::Server.get_status_update_frm_scheduler
     sch.inspect
  rescue CouchdbException => e
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

#delete status update by tag
delete '/status_updates/:tag*' do
   tag = params[:tag]
   update = Ragios::Server.delete_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
   end
end

#edit status update
put '/status_updates/:id*' do
 begin
   data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   id = params[:id]
   update = Ragios::Server.edit_status_update(id,data)
   if update.include?("_id") 
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


