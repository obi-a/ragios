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

#TODO add sinatra last_modified reduce computation and save bandwidth

class App < Sinatra::Base
before do
  content_type('application/json')
end

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
post '/monitors*', :check => :valid_token? do
 begin
  monitors = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
  controller.add(monitors)
  Yajl::Encoder.encode(monitors)
 rescue Exception => e   
  status 500
  body  Yajl::Encoder.encode({error: e.message})
 end
end

#get monitors that match multiple keys
get '/monitors*', :check => :valid_token? do
  pass if (params.keys[0] == "splat") && (params[params.keys[0]].kind_of?(Array))
  options = params
  options.delete("splat")
  options.delete("captures")
  monitors = controller.find_by(options)
  Yajl::Encoder.encode(monitors)
end

delete '/monitors/:id*', :check => :valid_token? do
  begin
    monitor_id = params[:id]
    hash = controller.delete(monitor_id)
    Yajl::Encoder.encode(hash)
  rescue Ragios::MonitorNotFound => e
    status 404
    Yajl::Encoder.encode({error: e.message})
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
  end 
end

#update an already existing monitor
put  '/monitors/:id*', :check => :valid_token? do
  begin
    pass unless request.media_type == 'application/json'
    data = Yajl::Parser.parse(request.body.read, :symbolize_keys => true)
    monitor_id = params[:id]
    updated_monitor = controller.update(monitor_id,data)
    Yajl::Encoder.encode(updated_monitor.options)
  rescue Ragios::MonitorNotFound => e
    status 404
    Yajl::Encoder.encode({error: e.message})
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
  end 
end

#stop a running monitor
put '/monitors/:id*', :check => :valid_token? do
  pass unless params["status"] == "stopped"
  monitor_id = params[:id]
  begin 
    controller.stop(monitor_id)
    Yajl::Encoder.encode({ ok: true})
  rescue Ragios::MonitorNotFound => e
    status 404
    Yajl::Encoder.encode({error: e.message})
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
  end 
end

#restart a running monitor
put '/monitors/:id*', :check => :valid_token? do
  pass unless params["status"] == "active"
  begin 
    monitor_id = params[:id]
    controller.restart(monitor_id)
    Yajl::Encoder.encode({ ok: true})
  rescue Ragios::MonitorNotFound => e
    status 404
    Yajl::Encoder.encode({error: e.message})
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
  end 
end

#get monitor by id
get '/monitors/:id*', :check => :valid_token? do
  begin
    monitor_id = params[:id]
    monitor = controller.get(monitor_id)
    Yajl::Encoder.encode(monitor) 
  rescue Ragios::MonitorNotFound => e
    status 404
    Yajl::Encoder.encode({error: e.message})
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
  end 
end

get '/monitors*', :check => :valid_token? do
  begin
    monitors =  controller.get_all
    Yajl::Encoder.encode(monitors)
  rescue Exception => e
    status 500
    Yajl::Encoder.encode({error: e.message})
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

end
