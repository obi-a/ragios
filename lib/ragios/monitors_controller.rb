#to be re-written
#copied as is from rest_server.rb
class MonitorsController < ApplicationController

  helpers do
    def controller
      @controller ||= Ragios::Controller
    end
  end

 #adds a monitor to the system and starts monitoring them
  post '/monitors*', :check => :valid_token? do
    try_request do
      monitor = parse_json(request.body.read)
      monitor_with_id = controller.add(monitor)
      generate_json(monitor_with_id)
    end
  end

  #tests a monitor
  post '/tests*', :check => :valid_token? do
    try_request do
      monitor_id = params[:id]
      controller.test_now(monitor_id)
      generate_json(ok: true)
    end
  end

  #get monitors that match multiple keys
  get '/monitors/attributes', :check => :valid_token? do
    pass if (params.keys[0] == "splat") && (params[params.keys[0]].kind_of?(Array))
    options = params
    options.delete("splat")
    options.delete("captures")
    monitors = controller.where(options)
    generate_json(monitors)
  end

  delete '/monitors/:id*', :check => :valid_token? do
    try_request do
      monitor_id = params[:id]
      controller.delete(monitor_id)
      generate_json(ok: true)
    end
  end

  #update an already existing monitor
  put  '/monitors/:id*', :check => :valid_token? do
    try_request do
      pass unless request.media_type == 'application/json'
      data = parse_json(request.body.read)
      monitor_id = params[:id]
      controller.update(monitor_id,data)
      generate_json(ok: true)
    end
  end

  #stop a running monitor
  put '/monitors/:id*', :check => :valid_token? do
    pass unless params["status"] == "stopped"
    monitor_id = params[:id]
    try_request do
      controller.stop(monitor_id)
      generate_json(ok: true)
    end
  end

  #start a stopped monitor
  put '/monitors/:id*', :check => :valid_token? do
    pass unless params["status"] == "active"
    try_request do
      monitor_id = params[:id]
      controller.start(monitor_id)
      generate_json(ok: true)
    end
  end

  get '/monitors/:id/events_by_type/:event_type*', :check => :valid_token? do
    try_request do
      events = controller.get_events_by_type(params[:id], params[:event_type], start_date: params[:end_date], end_date: params[:start_date], take: params[:take])
      generate_json(events)
    end
  end

  get '/monitors/:id/events_by_state/:state*', :check => :valid_token? do
    try_request do
      events =  controller.get_events_by_state(params[:id], params[:state], start_date: params[:end_date], end_date: params[:start_date], take: params[:take])
      generate_json(events)
    end
  end

  get '/monitors/:id/events*', :check => :valid_token? do
    try_request do
      events = controller.get_events(params[:id], start_date: params[:end_date], end_date: params[:start_date], take: params[:take])
      generate_json(events)
    end
  end

  #get monitor by id
  get '/monitors/:id*', :check => :valid_token? do
    try_request do
      monitor_id = params[:id]
      monitor = controller.get(monitor_id, include_current_state = true)
      generate_json(monitor)
    end
  end

  get '/monitors*', :check => :valid_token? do
    try_request do
      monitors =  controller.get_all(take: params[:take])
      generate_json(monitors)
    end
  end

  get '/admin/index' do
    check_logout
    content_type('text/html')
    erb :index
  end

  get '/admin/monitors/new' do
    check_logout
    content_type('text/html')
    erb :new
  end

  get '/admin/monitors/:id*' do
    check_logout
    @monitor = controller.get(params[:id])
    content_type('text/html')
    erb :monitor
  end
end
