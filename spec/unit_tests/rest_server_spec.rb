require 'spec_base.rb'
require 'sinatra_helper.rb'

def generate_json(str)
  JSON.generate(str)
end

def parse_json(json_str)
  JSON.parse(json_str, symbolize_names: true)
end

controller = Ragios::Controller

describe "Ragios rest server" do
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
      plugin: "mock_plugin"
    }
    post '/monitors*', monitor.to_json
    monitor_with_id = parse_json(last_response.body)
    last_response.should be_ok
    monitor_with_id.should include(monitor)
    monitor_with_id.should include(:_id, type: "monitor")
    controller.delete(monitor_with_id[:_id])
  end
  after(:all) do
    Ragios::CouchdbAdmin.get_database.delete
  end
end
