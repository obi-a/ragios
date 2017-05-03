#to be re-written
#copied as is from rest_server.rb
class EventsController < ApplicationController

  helpers do
    def events_ctr
      @events ||= Ragios::Events
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

  get '/admin/events/:id*' do
    check_logout
    @event_id = params[:id]
    content_type('text/html')
    erb :event, :layout => false
  end
end
