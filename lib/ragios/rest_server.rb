#require 'rubygems'
#require "bundler/setup"
#dir = Pathname(__FILE__).dirname.expand_path
#require dir + 'lib/ragios'
#require dir + 'config'
require 'sinatra/base'
require 'yajl'

#using config.yml with thin instead
#configure do
#    set :bind, 'localhost'
#    set :port, '5041'
#    set :server, %w[thin mongrel webrick]
    
# end


#TODO set Content-Type and other header attributes for each request
#TODO add sinatra last_modified reduce computation and save bandwidth

class App < Sinatra::Base

register do
  def check (name)
    condition do
      unless send(name) == true
        error 401, Yajl::Encoder.encode({ error: "You are not authorized to access this resource"})
      end
    end
  end
end

helpers do
  def valid_key?
    Ragios::Admin.valid_key?(request.cookies["AuthSession"]) 
  end
end

get '/' do
  content_type('application/json')
  Yajl::Encoder.encode({ "Ragios Server" => "welcome"})
end

post '/session*' do
  if Ragios::Admin.authenticate?(params[:username],params[:password])   
    Yajl::Encoder.encode({ AuthSession: Ragios::Admin.session })
  else
   status 401
   Yajl::Encoder.encode({ error: "You are not authorized to access this resource"})
  end 
end

#adds monitors to the system and starts monitoring them
post '/monitors*', :check => :valid_key? do
 begin
  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  Ragios::Monitor.start monitors,server=TRUE
  content_type('application/json')
  Yajl::Encoder.encode({ok:"true"})
 rescue 
  content_type('application/json')
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

get '/monitors/:key/:value*', :check => :valid_key? do
    key = params[:key].to_sym
    value = params[:value]
    monitors = Ragios::Server.find_monitors(key => value)
    m = Yajl::Encoder.encode(monitors)
    content_type('application/json')
    if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ error: "not_found"})
    else 
      m
    end
end

delete '/monitors/:id*', :check => :valid_key? do
   id = params[:id]
   hash = Ragios::Server.delete_monitor(id)
   content_type('application/json')
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
put '/monitors/:id/state/stopped*', :check => :valid_key? do
   id = params[:id]
   hash = Ragios::Server.stop_monitor(id)
   content_type('application/json')
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
put '/monitors/:id/state/active*', :check => :valid_key? do
  begin 
   id = params[:id]
    m = Ragios::Server.restart_monitor(id)
    content_type('application/json')
   if m[0].class == Ragios::GenericMonitor
    status 200
    Yajl::Encoder.encode({ok: 'true'})
   end
  rescue => e
   if e.to_s == "monitor not found"
    status 404
    body  Yajl::Encoder.encode({error: 'not_found', check: 'monitor_id'}) 
   else
    status 500
    body  Yajl::Encoder.encode({error: e.to_s})
   end
  end
end

#edit an already existing monitor
put  '/monitors/:id*', :check => :valid_key? do
  begin
    data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
    id = params[:id]
    Ragios::Server.update_monitor(id,data)
    content_type('application/json')
    Yajl::Encoder.encode({ "ok" => "true"})
  rescue 
  content_type('application/json')
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

get '/scheduler/monitors/:id*', :check => :valid_key? do
  begin
     id = params[:id]
     sch = Ragios::Server.get_monitors_frm_scheduler(id)
     content_type('application/json')
     sch.inspect
  rescue CouchdbException => e
     content_type('application/json')
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/scheduler/monitors*', :check => :valid_key? do
  begin
     sch = Ragios::Server.get_monitors_frm_scheduler
     content_type('application/json')
     sch.inspect
  rescue CouchdbException => e
     content_type('application/json')
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/monitors/:id*', :check => :valid_key? do
  begin
   id = params[:id]
   monitor = Ragios::Server.get_monitor(id)
   content_type('application/json')
   Yajl::Encoder.encode(monitor) 
 rescue CouchdbException => e
   if e.to_s == 'CouchDB: Error - not_found. Reason - missing'
     content_type('application/json')
     status 404
     Yajl::Encoder.encode({ "error" => e.error, check: 'monitor_id'})
   else
    raise
   end
 end 
end

get '/monitors*', :check => :valid_key? do
  monitors =  Ragios::Server.get_all_monitors
  content_type('application/json')
  m = Yajl::Encoder.encode(monitors)
  if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ "error" => "not_found"})
  else 
    m
  end
end



#status updates
get '/status_updates/:key/:value*', :check => :valid_key? do
 key = params[:key].to_sym
 value = params[:value]
 monitors = Ragios::Server.find_status_update(key => value)
 content_type('application/json')
 m = Yajl::Encoder.encode(monitors) 
 if m.to_s == '[]'
  status 404
  Yajl::Encoder.encode({ "error" => "not_found"})
 else 
   m
 end
end


post '/status_updates*', :check => :valid_key? do
  begin
   config = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   Ragios::Server.start_status_update(config)
   content_type('application/json')
   status 200
   Yajl::Encoder.encode({ok:"true"})
  rescue 
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end

end

#restart a status update
put '/status_updates/:tag/state/active*', :check => :valid_key? do
   tag = params[:tag]
   content_type('application/json')
   update = Ragios::Server.restart_status_updates(tag)
   if update == nil 
      status 404
      Yajl::Encoder.encode({ "error" => "no stopped status update found for named tag"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     status 200
     Yajl::Encoder.encode({ok:'true'})
  end
end

#stop a status update
put '/status_updates/:tag/state/stopped*', :check => :valid_key? do
   tag = params[:tag]
   content_type('application/json')
   update = Ragios::Server.stop_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     status 200
     Yajl::Encoder.encode({ok:'true'})
   end
end

get '/scheduler/status_updates/:tag*', :check => :valid_key? do
  begin
     tag = params[:tag]
     sch = Ragios::Server.get_status_update_frm_scheduler(tag)
     content_type('application/json')
     sch.inspect
  rescue CouchdbException => e
     content_type('application/json')
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

get '/scheduler/status_updates*', :check => :valid_key? do
  begin
     sch = Ragios::Server.get_status_update_frm_scheduler
     content_type('application/json')
     sch.inspect
  rescue CouchdbException => e
     content_type('application/json')
     status 500
     body  Yajl::Encoder.encode({error: "something went wrong"})
  end
end

#delete status update by tag
delete '/status_updates/:tag*', :check => :valid_key? do
   tag = params[:tag]
   content_type('application/json')
   update = Ragios::Server.delete_status_update(tag)
   if update == []
      status 404
      Yajl::Encoder.encode({ "error" => "not found"})
   else update[0].include?("_id") && update[0].include?("_rev") && update[0].include?(tag)
     Yajl::Encoder.encode({ok:'true'})
   end
end

#edit status update
put '/status_updates/:id*', :check => :valid_key? do
 begin
   data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
   id = params[:id]
   content_type('application/json')
   update = Ragios::Server.edit_status_update(id,data)
   if update.include?("_id") 
       Yajl::Encoder.encode({ok:'true'})
   else
       status 500
        Yajl::Encoder.encode({error:'unknown'})
   end
  rescue CouchdbException => e
   if e.to_s == 'CouchDB: Error - not_found. Reason - missing'
     content_type('application/json')
     status 404
     Yajl::Encoder.encode({ "error" => e.error, check: 'status_update_id'})
   else
    raise
   end
  end
end

get '/status_updates/:id*', :check => :valid_key? do
  begin
   id = params[:id]
   status_update = Ragios::Server.get_status_update(id)
   content_type('application/json')
   Yajl::Encoder.encode(status_update) 
 rescue CouchdbException => e
   if e.to_s == 'CouchDB: Error - not_found. Reason - missing'
     content_type('application/json')
     status 404
     Yajl::Encoder.encode({ "error" => e.error, check: 'status update id'})
   else
    raise
   end
 end 
end

get '/status_updates*', :check => :valid_key? do
  updates =  Ragios::Server.get_all_status_updates
  content_type('application/json')
  u = Yajl::Encoder.encode(updates)
  if u.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ "error" => "not_found"})
  else 
    u
  end
end

get '/*' do 
  status 400
  content_type('application/json')
  Yajl::Encoder.encode({ error: "bad_request"})
end

put '/*' do 
  status 400
  content_type('application/json')
  Yajl::Encoder.encode({ error: "bad_request"})
end

post '/*' do 
  status 400
  content_type('application/json')
  Yajl::Encoder.encode({ error: "bad_request"})
end

delete '/*' do 
  status 400
  content_type('application/json')
  Yajl::Encoder.encode({ error: "bad_request"})
end

end
