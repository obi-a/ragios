#to be re-written
class AppController < Sinatra::Base
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

  get '/admin/index' do
    check_logout
    content_type('text/html')
    erb :index
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


  def check_logout
    token = request.cookies['RagiosAuthSession']
    if logged_out?(token)
      redirect '/admin/login'
    end
  end

protected

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
