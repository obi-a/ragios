require 'spec_base.rb'

events = Ragios::Events

describe Ragios::Events do
  before(:all) do
    database_name = "test_ragios_events_#{Time.now.to_i}"
    database_admin = {
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      database: database_name,
      address: 'http://localhost',
      port: '5984'
    }

    Ragios::CouchdbAdmin.config(database_admin)
    Ragios::CouchdbAdmin.setup_database
    @database = Ragios::CouchdbAdmin.get_database
  end

  before(:each) do
    @database.create_doc("event1", type: "event", time: Time.now)
    @database.create_doc("event2", type: "event", time: Time.now)
    @database.create_doc("event3", type: "event", time: Time.now)
  end

  describe "#get" do
    it "returns event by id" do
      events.get("event1").should  include(_id: "event1")
    end
    it "raises error when event is not found" do
      expect{ events.get("not_found") }.to raise_error(Ragios::EventNotFound)
    end
    it "only returns documents of type event" do
      @database.create_doc("some_doc", type: "some_type")
      expect{ events.get("some_doc") }.to raise_error(Ragios::EventNotFound)
    end
  end
  describe "#all" do
    it "returns all events ordered with the latest event first" do
      all_events = events.all
      all_events.first.should include(_id: "event3")
      all_events.count.should == 3
    end
    it "can return events by a limit" do
      events.all(take: 2).count.should == 2
    end
    it "returns events by a daterange" do
      events.all(end_date: "2013", start_date: "2014").should == []
    end
  end
  describe "#delete" do
    it "deletes an event" do
      @database.create_doc("event4", type: "event", time: Time.now)
      events.delete("event4")
      expect{ events.get("event4") }.to raise_error(Ragios::EventNotFound)
    end
    it "cannot delete an event that doesn't exist" do
      expect{ events.delete("not_found") }.to raise_error(Ragios::EventNotFound)
    end
  end
  after(:each) do
    @database.delete_doc!("event1")
    @database.delete_doc!("event2")
    @database.delete_doc!("event3")
  end
  after(:all) do
    @database.delete
    Ragios::Events.reset
  end
end
