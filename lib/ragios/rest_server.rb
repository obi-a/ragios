class App < Sinatra::Base
  before do
    content_type('application/json')
  end

  enable :sessions

  register do
    def check (name)
      condition do
        unless send(name) == true
          error 401, generate_json(error: "You are not authorized to access this resource")
        end
      end
    end
  end

  helpers do
    def valid_token?
      Ragios::Admin.valid_token?(request.cookies["RagiosAuthSession"])
    end
    def controller
      @controller ||= Ragios::Controller
    end
    def events_ctr
      @events ||= Ragios::Events
    end
  end

  get '/' do
    redirect '/admin/index'
  end

  get '/favicon.ico' do
    redirect '/images/favicon.ico'
  end

  post '/session*' do
    if Ragios::Admin.authenticate?(params[:username],params[:password])
      generate_json(RagiosAuthSession: Ragios::Admin.session)
    else
      status 401
      generate_json(error: "You are not authorized to access this resource")
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

  delete '/events/:id*', :check => :valid_token? do
    try_request do
      event_id = params[:id]
      events_ctr.delete(event_id)
      generate_json(ok: true)
    end
  end

  #get event by id
  get '/events/:id*', :check => :valid_token? do
    try_request do
      event_id = params[:id]
      event = events_ctr.get(event_id)
      generate_json(event)
    end
  end

  get '/events*', :check => :valid_token? do
    try_request do
      events =  events_ctr.all(take: params[:take])
      generate_json(events)
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

  get '/admin/events/:id*' do
    check_logout
    @event_id = params[:id]
    content_type('text/html')
    erb :event, :layout => false
  end

  get '/admin/login' do
    @login_page = true
    content_type('text/html')
    erb :login
  end

  post '/admin_session*' do
    @login_page = true
    if Ragios::Admin.authenticate?(params[:username], params[:password])
      response.set_cookie "RagiosAuthSession", Ragios::Admin.session
      session[:authenticated] = true
      redirect '/admin/index'
    else
      @error = "Invalid username and/or password"
      content_type('text/html')
      erb :login
    end
  end

  get '/admin/logout' do
    token = request.cookies['RagiosAuthSession']
    response.delete_cookie "RagiosAuthSession"
    session.clear
    Ragios::Admin.invalidate_token(token)
    redirect '/admin/login'
  end

  get '/*' do
    status 400
    bad_request
  end

  put '/*' do
    status 400
    bad_request
  end

  post '/*' do
    status 400
    bad_request
  end

  delete '/*' do
    status 400
    bad_request
  end

  def check_logout
    token = request.cookies['RagiosAuthSession']
    if logged_out?(token)
      redirect '/admin/login'
    end
  end

private

  def logged_out?(token)
    return false if !Ragios::Admin.do_authentication?
    (!session[:authenticated] || !Ragios::Admin.valid_token?(token)) ? true : false
  end

  def bad_request
    generate_json(error: "bad_request")
  end

  def try_request
    yield
  rescue Ragios::MonitorNotFound, Ragios::EventNotFound => e
    status 404
    body generate_json(error: e.message)
  rescue => e
    controller.send_stderr(e)
    status 500
    body generate_json(error: e.message)
  end

  def generate_json(str)
    JSON.generate(str)
  end
  def parse_json(json_str)
    JSON.parse(json_str, symbolize_names: true)
  end
end
