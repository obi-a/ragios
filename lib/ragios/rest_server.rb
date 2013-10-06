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
  def valid_token?
    Ragios::Admin.valid_token?(request.cookies["AuthSession"]) 
  end
  def controller
    @controller ||= Ragios::Controller
  end
end

get '/' do
  content_type('application/json')
  Yajl::Encoder.encode({ "Ragios Server" => "welcome"})
end

post '/session*' do
  if Ragios::Admin.authenticate?(params[:username],params[:password])
    content_type('application/json')   
    Yajl::Encoder.encode({ AuthSession: Ragios::Admin.session })
  else
   status 401
   Yajl::Encoder.encode({ error: "You are not authorized to access this resource"})
  end 
end

#adds monitors to the system and starts monitoring them
post '/monitors*', :check => :valid_token? do
 begin
  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  controller.add_monitors(monitors)
  content_type('application/json')
  Yajl::Encoder.encode({ok:"true"})
 rescue 
  content_type('application/json')
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

get '/monitors*', :check => :valid_token? do
    pass if (params.keys[0] == "splat") && (params[params.keys[0]].kind_of?(Array))
    key = params.keys[0]
    value = params[key]
    monitors = controller.find_monitors(key.to_sym => value)
    m = Yajl::Encoder.encode(monitors)
    content_type('application/json')
    if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ error: "not_found"})
    else 
      m
    end
end

delete '/monitors/:id*', :check => :valid_token? do
   id = params[:id]
   hash = controller.delete_monitor(id)
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

#edit an already existing monitor
put  '/monitors/:id*', :check => :valid_token? do
  begin
    pass unless request.media_type == 'application/json'
    data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
    id = params[:id]
    controller.update_monitor(id,data)
    content_type('application/json')
    Yajl::Encoder.encode({ "ok" => "true"})
  rescue 
  content_type('application/json')
  status 500
  body  Yajl::Encoder.encode({error: "something went wrong"})
 end
end

#stop a running monitor
put '/monitors/:id*', :check => :valid_token? do
   pass unless params["state"] == "stopped"
   id = params[:id]
   hash = controller.stop_monitor(id)
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
put '/monitors/:id*', :check => :valid_token? do
  pass unless params["state"] == "active"
  begin 
    id = params[:id]
    m = controller.restart_monitor(id)
    content_type('application/json')
    status 200
    Yajl::Encoder.encode({ok: 'true'})
  rescue Ragios::MonitorNotFound
    status 404
    body  Yajl::Encoder.encode({error: "No monitor found with id = #{id}"}) 
  end
end

get '/monitors/:id*', :check => :valid_token? do
  begin
   id = params[:id]
   monitor = controller.get_monitor(id)
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

get '/monitors*', :check => :valid_token? do
  monitors =  controller.get_all_monitors
  content_type('application/json')
  m = Yajl::Encoder.encode(monitors)
  if m.to_s == '[]'
     status 404
     Yajl::Encoder.encode({ "error" => "not_found"})
  else 
    m
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
