require 'spec_base.rb'
require 'sinatra_helper.rb'

def generate_json(str)
  JSON.generate(str)
end

def parse_json(json_str)
  JSON.parse(json_str, symbolize_names: true)
end

def monitor_manager
  Ragios::Monitors::GenericMonitor
end

plugin = "mock_plugin"
notifiers = ["log_notifier"]

describe "Ragios REST API" do
  it "redirects to home & returns 302" do
    get "/"
    expect(last_response.status).to eq(302)
  end

  describe "adding monitors" do
    context "when valid attributes are provided" do
      it "adds a new monitor" do
        monitor = {
          monitor: "My Website",
          url: "http://mysite.com",
          every: "5h",
          contact: "obi.akubue@gmail.com",
          via: notifiers,
          plugin: plugin
        }

        post "/monitors", monitor.to_json
        expect(last_response.status).to eq(200)
        created_monitor = parse_json(last_response.body)
        expect(created_monitor).to include(monitor)
        expect(created_monitor).to include(type: "monitor")
        monitor_manager.delete(created_monitor[:_id])
      end
    end
    context "when invalid attributes are provided" do
      it "returns a 500 error code with correct error message" do
        monitor = {
          monitor: "Google",
          url: "http://google.com",
          every: "5m",
          contact: "admin@mail.com",
          plugin: plugin
        }

        post '/monitors*', monitor.to_json
        expect(last_response.status).to eq(500)
        expect(last_response.body).to include("No Notifier Found")
      end
    end
    context "when bad data is provided" do
      it "returns a 500 error" do
       post '/monitors*',"bad data"
       expect(last_response.status).to eq(500)
      end
    end
  end

  describe "Monitor Operational API" do
    before(:each) do
      @unique_name = SecureRandom.uuid
      @interval = "5h"
      @monitor = {
        monitor:  @unique_name,
        url: "http://google.com",
        every: @interval,
        contact: "admin@mail.com",
        via: notifiers,
        plugin: plugin
      }

      @monitor_id = monitor_manager.create(@monitor).id
    end

    describe "fetching a monitor by id" do
      context "when a valid monitor_id is provided" do
        it "returns the monitor" do
          get "/monitors/#{@monitor_id}"
          expect(last_response.status).to eq(200)
          returned_monitor = parse_json(last_response.body)
          expect(returned_monitor).to include(@monitor)
          expect(returned_monitor).to include(type: "monitor")
          expect(returned_monitor.keys).to include(:current_state)
        end
      end
      context "when monitor is not found" do
        it "returns a 404 status not found error" do
          get "/monitors/not_found"
          expect(last_response.status).to eq(404)
          expect(parse_json(last_response.body)).to include(error: "No monitor found with id = not_found")
        end
      end
    end

    describe "Querying monitors that match provided attributes" do
      context "when there exists monitors that match the provided attributes" do
        it "returns the monitors" do
          options = {monitor: @unique_name, every: @interval}
          get "/monitors/attributes?#{URI.encode_www_form(options)}"
          results = parse_json(last_response.body)
          expect(results.count).to eq(1)
          expect(results.first).to include(options)
          expect(results.first[:_id]).to eq(@monitor_id)
          expect(results.first).to include(type: "monitor")
        end
      end
      context "when no monitors match the provided attributes" do
        it "returns an empty list" do
          options = {monitor: "not_found", every: "5m", something: "dont_exist"}
          get "/monitors/attributes?#{URI.encode_www_form(options)}"

          results = parse_json(last_response.body)
          expect(results).to eq([])
        end
      end
    end

    describe "Updating a Monitor" do
      context "when valid attributes are provided" do
        it "updates the monitor" do
          update_options = {every: "10h", via: ["log_notifier"]}
          put "/monitors/#{@monitor_id}", update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
          expect(last_response.status).to eq(200)
          expect(parse_json(last_response.body)).to eq(ok: true)
          updated_monitor = monitor_manager.find(@monitor_id).options
          expect(updated_monitor).to include(update_options)
        end
      end
      context "when reserved attributes are provided" do
        it "returns a 500 error" do
          update_options = {status_: "stopped"}
          put "/monitors/#{@monitor_id}", update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
          expect(last_response.status).to eq(500)
          expect(last_response.body).to include("Cannot edit system settings")
        end
      end
      context "when monitor doesn't exist" do
        it "returns a 404 not found error" do
          update_options = {every: "10h", via: ["log_notifier"]}
          put "/monitors/not_found", update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
          expect(last_response.status).to eq(404)
          expect(last_response.body).to include("No monitor found with id = not_found")
        end
      end
    end

    describe "Trigger a monitor" do
      context "when the monitor exists" do
        it "triggers the monitor" do
          post '/tests*', id: @monitor_id
          expect(last_response.status).to eq(200)
          expect(parse_json(last_response.body)).to eq(ok: true)
        end
      end
      context "when the monitor doesn't exist" do
        it "returns a 500 error" do
          post '/tests*', id: "not_found"
          expect(last_response.status).to eq(404)
          expect(last_response.body).to include("No monitor found with id = not_found")
        end
      end
    end

    describe "Stop a monitor" do
      context "when monitor exists" do
        it "stops the monitor" do
          put "/monitors/#{@monitor_id}", status: "stopped"
          expect(last_response.status).to eq(200)
          expect(parse_json(last_response.body)).to eq(ok: true)
          expect(monitor_manager.find(@monitor_id).options[:status_]).to eq("stopped")
        end
      end
      context "when the monitor doesn't exist" do
        it "returns a 500 error" do
          put "/monitors/not_found", status: "stopped"
          expect(last_response.status).to eq(404)
          expect(last_response.body).to include("No monitor found with id = not_found")
        end
      end
    end

    describe "Start a monitor" do
      context "when monitor exists" do
        it "starts the monitor" do
          put "/monitors/#{@monitor_id}", status: "active"
          expect(last_response.status).to eq(200)
          expect(parse_json(last_response.body)).to eq(ok: true)
          expect(monitor_manager.find(@monitor_id).options[:status_]).to eq("active")
        end
      end
      context "when the monitor doesn't exist" do
        it "returns a 404 error" do
          put "/monitors/not_found", status: "active"
          expect(last_response.status).to eq(404)
          expect(last_response.body).to include("No monitor found with id = not_found")
        end
      end
    end

    after(:each) do
      monitor_manager.delete(@monitor_id)
    end
  end
  describe "Delete Monitor" do
    context "when monitor exists" do
      it "deletes the monitor" do
        unique_name = SecureRandom.uuid
        monitor = {
          monitor:  unique_name,
          url: "http://google.com",
          every: "5h",
          contact: "admin@mail.com",
          via: notifiers,
          plugin: plugin
        }
        monitor_id = monitor_manager.create(monitor).id
        delete "/monitors/#{monitor_id}"
        expect(last_response.status).to eq(200)
        expect(parse_json(last_response.body)).to eq(ok: true)
        expect(monitor_manager.model.monitors_where(monitor: unique_name)).to eq([])
      end
    end
    context "when monitor doesn;t exist" do
      it "returns a 404 error" do
        delete "/monitors/not_found"
        expect(last_response.status).to eq(404)
        expect(last_response.body).to include("No monitor found with id = not_found")
      end
    end
  end
  describe "Bad Requests" do
    context "when it receives bad requests" do
      it "returns 400 response code" do
        expect(put('/xyz').status).to eq(400)
        expect(delete('/xyz').status).to eq(400)
        expect(post('/xyz').status).to eq(400)
        expect(get('/xyz').status).to eq(400)
      end
    end
  end

  describe "Events API" do
    before(:all) do
      @params = { start_date: "2000", end_date: "2013", limit: 1}
    end
    it "returns all events by date range for specified monitor" do
      get '/monitors/mymonitor/events', @params
      expect(last_response.status).to eq(200)
    end
    it "returns all notifications for specified monitor" do
      get '/monitors/mymonitor/events_by_type/monitor.notification', @params
      expect(last_response.status).to eq(200)
    end
    it "returns all events by state for specified monitor" do
      get '/monitors/mymonitor/events_by_state/failed', @params
      expect(last_response.status).to eq(200)
    end

    describe "More Events API" do
      before(:each) do
        monitor_manager.model.save("event1", type: "event", time: Time.now)
        monitor_manager.model.save("event2", type: "event", time: Time.now)
        monitor_manager.model.save("event3", type: "event", time: Time.now)
      end
      it "returns event by id" do
        get '/events/event1'
        expect(last_response.status).to eq(200)
      end
      it "returns all events" do
        get "/events?#{URI.encode_www_form(@params)}"
        expect(last_response.status).to eq(200)
      end
      it "deletes an event" do
        unique_event_name = SecureRandom.uuid
        monitor_manager.model.save(unique_event_name, type: "event", time: Time.now)
        delete "/events/#{unique_event_name}"
        expect(last_response.status).to eq(200)
      end
      after(:each) do
        monitor_manager.model.delete("event1")
        monitor_manager.model.delete("event2")
        monitor_manager.model.delete("event3")
      end
    end
  end
  describe "Authentication" do
    context "when valid credentials are provided" do
      it "authenticates user" do
        post '/session', username: Ragios::ADMIN[:username], password: Ragios::ADMIN[:password]
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("RagiosAuthSession")
      end
    end
    context "when user authentication fails" do
      it "returns 401 status" do
        post '/session', username: "something_else", password: "something_else"
        expect(last_response.status).to eq(401)
        expect(last_response.body).to include("You are not authorized to access this resource")
      end
    end
  end
  describe "Retrieving all monitors" do
    it "returns all monitors" do
      expect(get('/monitors').status).to eq(200)
    end
  end
end
