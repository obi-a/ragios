require 'spec_base.rb'
require 'sinatra_helper.rb'

def generate_json(str)
  JSON.generate(str)
end

def parse_json(json_str)
  JSON.parse(json_str, symbolize_names: true)
end

plugin = "mock_plugin"
controller = Ragios::Controller

describe "Ragios REST API" do
  before(:all) do
    Ragios::Admin.config(authentication: false)

    #database configuration
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: 'ragios_test_rest_server_database',
      address: 'http://localhost',
      port: '5984'
    }
    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
  end
  it "adds a monitor" do
    monitor = {
      monitor: "My Website",
      url: "http://mysite.com",
      every: "5m",
      contact: "obi.akubue@gmail.com",
      via: ["gmail_notifier"],
      plugin: plugin
    }
    post '/monitors*', monitor.to_json
    monitor_with_id = parse_json(last_response.body)
    last_response.should be_ok
    monitor_with_id.should include(monitor)
    monitor_with_id.should include(:_id, type: "monitor")
    controller.delete(monitor_with_id[:_id])
  end
  it "adds a monitor with multiple notifiers" do
    monitor = {
      monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: ["gmail_notifier","twitter_notifier"],
      plugin: plugin
    }
    post '/monitors*', monitor.to_json
    monitor_with_id = parse_json(last_response.body)
    last_response.should be_ok
    monitor_with_id.should include(monitor)
    monitor_with_id.should include(:_id, type: "monitor")
    controller.delete(monitor_with_id[:_id])
  end
  it "cannot add a monitor with no plugin" do
    monitor = {
      monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      via: "gmail_notifier"
    }

    post '/monitors*', monitor.to_json
    last_response.status.should == 500
    last_response.body.should include("No Plugin Found")
  end
  it "cannot add a monitor with no notifier" do
    monitor = {
      monitor: "Google",
      url: "http://google.com",
      every: "5m",
      contact: "admin@mail.com",
      plugin: plugin
    }

    post '/monitors*', monitor.to_json
    last_response.status.should == 500
    last_response.body.should include("No Notifier Found")
  end
  it "cannot add a badly formed monitor" do
    post '/monitors*',"bad data"
    last_response.status.should == 500
  end

  describe "more API calls" do
    before(:each) do
      @unique_name = "Google #{Time.now.to_i}"
      @monitor = {
        monitor:  @unique_name,
        url: "http://google.com",
        every: "5m",
        contact: "admin@mail.com",
        via: ["gmail_notifier"],
        plugin: plugin
      }
      @monitor_id = controller.add(@monitor)[:_id]
    end
    describe "Fetch Monitors API: get /monitor/:id" do
      it "retrieves a monitor by id" do
        get '/monitors/' + @monitor_id
        last_response.should be_ok
        parse_json(last_response.body).should include(@monitor)
      end
      it "returns a 404 status when monitor is not found" do
        get '/monitors/' + "not_found"
        last_response.status.should == 404
        parse_json(last_response.body).should include(error: "No monitor found with id = not_found")
      end
    end
    describe "query monitors that match attributes: get /monitors* " do
      it "find monitors that match multiple key/value pairs" do
        options = {monitor: @unique_name, every: '5m'}
        get '/monitors*', options
        results = parse_json(last_response.body)
        results.count.should == 1
        results.first.should include(options)
      end
      it "returns an empty array when no monitor matches multiple key/value pairs" do
        get '/monitors*', monitor: "not_found", every: "5m", something: "dont_exist"
      end
    end
    describe "Updates API" do
      it "updates an active monitor" do
        update_options = {every: "10m", via: ["twitter_notifier"]}
        put '/monitors/' + @monitor_id, update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.should be_ok
        controller.get(@monitor_id)[:status_].should == "active"

        #monitor update is idempotent
        put '/monitors/' + @monitor_id, update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.should be_ok
        controller.get(@monitor_id)[:status_].should == "active"
      end
      it "updates a stopped monitor" do
        controller.stop(@monitor_id)
        update_options = {every: "10m", via: ["twitter_notifier"]}
        put '/monitors/' + @monitor_id, update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.should be_ok
        controller.get(@monitor_id)[:status_].should == "stopped"
      end
      it "cannot update a monitor with bad data" do
        put '/monitors/' + @monitor_id, "bad data", {'CONTENT_TYPE'=>'application/json'}
        last_response.status.should == 500
      end
      it "cannot update a monitor that doesn't exist" do
        update_options = {every: "5m", via: ["twitter_notifier"]}
        put '/monitors/' + "not_found", update_options.to_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.status.should == 404
      end
    end
    after(:each) do
      controller.delete(@monitor_id)
    end
  end
  after(:all) do
    Ragios::CouchdbAdmin.get_database.delete
  end
end
