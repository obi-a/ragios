require 'spec_base.rb'

describe "Ragios::Database::Model" do
  before(:all) do
    @database = Leanback::Couchdb.new(
      database: "ragios_test_model_database#{Time.now.to_i}",
      address: "http://localhost",
      username: ENV['COUCHDB_ADMIN_USERNAME'],
      password: ENV['COUCHDB_ADMIN_PASSWORD'],
      port: "5984"
    )
    @database.create
    @model =  Ragios::Database::Model.new(@database)
  end
  describe "basic database operatons" do
    before(:each) do
      @database.create_doc("exists", name: "some document")
    end
    describe "#save" do
      it "should save the document" do
        @model.save("linda", name: "ragios").should == true

        @database.delete_doc!("linda")
      end
      it "cannot save a document with an id that already exists" do
        expect { @model.save("exists", something: "something") }.to raise_error(Leanback::CouchdbException)
      end
    end
    describe "#find" do
      it "returns a document by id" do
        doc = @model.find("exists")
        doc.should include(_id: "exists", name: "some document")
      end
      it "raises exception when the document cannot be found" do
        expect { @model.find("dont_exist") }.to raise_error(Leanback::CouchdbException)
      end
    end
    describe "#update" do
      it "updates a document by id" do
        @model.update("exists", name: "a change").should == true
      end
      it "raises an exception when document id does not exist" do
        expect { @model.update("dont_exists", name: "a change", other: nil, number: 1) }.to raise_error(Leanback::CouchdbException)
      end
    end
    describe "#delete" do
      it "deletes a document" do
        @model.save("john", name: "ragios")
        @model.delete("john").should == true
      end
      it "raises an exception when document with provided id cannot be found" do
        expect{ @model.delete("dont_exist") }.to raise_error(Leanback::CouchdbException)
      end
    end
    describe "monitors data" do
      before(:each) do
        for count in 1..2 do
          monitor = {
            monitor: "website #{count}",
            every:  "#{count}m",
            type: "monitor",
            status_: "stopped",
            created_at_: Time.now
          }
          @database.create_doc "monitor_#{count}", monitor

          other_monitor = {
            monitor: "website 3",
            every:  "3m",
            type: "monitor",
            status_: "active",
            created_at_: Time.now
          }
        end
        @database.create_doc "monitor_3", other_monitor
      end
      describe "#all_monitors" do
        it "returns all monitors" do
          #all_monitors results are ordered by document_date monitor[:created_at_]
          @model.all_monitors.first.should include(_id: "monitor_3")
          @model.all_monitors.last.should include(_id: "monitor_1")
        end
        it "can limit results" do
          @model.all_monitors(take: 2).count.should == 2
        end
      end
      describe "#monitors_where" do
        it "returns monitors that match provided attributes" do
          @model.monitors_where(status_: "active").first.should include(_id: "monitor_3")
        end
        it "returns an empty array when no attributes match" do
          @model.monitors_where(monitor: "doesn't exist").should == []
        end
        it "Returns an empty array when key doesnt exist" do
          @model.monitors_where(dont_exist: "doesn't exist").should == []
        end
      end
      after(:each) do
        for count in 1..3 do
          @database.delete_doc! "monitor_#{count}"
        end
      end
    end
    describe "#get_monitor_state" do
      it "returns nil when monitor has no test_result" do
        @model.get_monitor_state("no_test_result").should == {}
      end
      it "returns monitors current state" do
        for count in 1..5 do
          time = Time.now
          timestamp = time.to_i
          test_result = {
            monitor_id: "my_monitor",
            state: "failed",
            event: {winner: "chicken dinner"},
            time: time,
            timestamp: timestamp,
            monitor: {},
            event_type: "monitor.test",
            type: "event"
          }
          @database.create_doc  "activity#{count}", test_result
        end
        latest_time = Time.now
        latest_timestamp = time.to_i
        latest_test_result = {
          monitor_id: "my_monitor",
          state: "failed",
          event: {winner: "chicken dinner"},
          time: latest_time,
          timestamp: latest_timestamp,
          monitor: {},
          event_type: "monitor.test",
          type: "event"
        }
        @database.create_doc "latest_activity", latest_test_result

        @model.get_monitor_state("my_monitor").should include(_id: "latest_activity", timestamp: latest_timestamp)

        for count in 1..5 do
          @database.delete_doc! "activity#{count}"
        end
        @database.delete_doc! "latest_activity"
      end
    end
    describe "#get_monitor_events_by_state" do
      before(:each) do
        for count in 1..5 do
          time = Time.now
          timestamp = time.to_i
          event = {
            monitor_id: "my_monitor",
            state: "failed",
            event: {winner: "chicken dinner"},
            time: time,
            timestamp: timestamp,
            monitor: {},
            event_type: "monitor.test",
            type: "event"
          }
          @database.create_doc  "event_by_state_#{count}", event
        end
      end

      it "returns all events by specified state over the provided date range" do
        events = @model.get_monitor_events_by_state("my_monitor", "failed", start_date: "3015-01-15 05:30:00 -0500", end_date: "1913")
        events.first[:_id].should == "event_by_state_5"
        events.last[:_id].should == "event_by_state_1"
        events.count.should == 5

        @model.get_monitor_events_by_state("my_monitor", "passed", start_date: "3015", end_date: "1913").should == []
        @model.get_monitor_events_by_state("my_monitor", "passed", start_date: "2000", end_date: "1980").should == []

        events = @model.get_monitor_events_by_state("my_monitor", "failed", start_date: "3015", end_date: "1913", take: 2)
        events.first[:_id].should == "event_by_state_5"
        events.last[:_id].should == "event_by_state_4"
        events.count.should == 2

        expect { @model.get_monitor_events_by_state("not_found", "failed", start_date: "1913", end_date: "3015") }.to raise_error(Leanback::CouchdbException)
        expect { @model.get_monitor_events_by_state("not_found", "failed", {}) }.to raise_error(Leanback::CouchdbException)
      end

      after(:each) do
        for count in 1..5 do
          @database.delete_doc! "event_by_state_#{count}"
        end
      end
    end
    describe "#get_monitor_events_by_type" do
      before(:each) do
        for count in 1..5 do
          time = Time.now
          timestamp = time.to_i
          notification = {
            monitor_id: "my_monitor",
            state: "failed",
            event: {winner: "chicken dinner"},
            time: time,
            timestamp: timestamp,
            monitor: {},
            event_type: "monitor.notification",
            type: "event",
            notifier: "notifier"
          }
          @database.create_doc "notification_#{count}", notification
        end
      end
      it "returns all events by type for specified monitor within the specified date range" do
        notifications = @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "3015", end_date: "1913")
        notifications.first[:_id].should == "notification_5"
        notifications.last[:_id].should == "notification_1"
        notifications.count.should == 5
      end
      it "can limit the number of events returned in the query" do
        notifications = @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "3015", end_date: "1913", take: 2)
        notifications.first[:_id].should == "notification_5"
        notifications.last[:_id].should == "notification_4"
        notifications.count.should == 2
      end
      it "returns an empty array when no event is found within the date range" do
        @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "1990", end_date: "1980").should == []
      end
      it "returns an empty array when monitor is not found" do
        @model.get_monitor_events_by_type("not_found", "monitor.notification", start_date: "3015", end_date: "1913").should == []
      end
      it "raises an exception when start_date and end_date is reversed or missing" do
        expect{ @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "1913", end_date: "3015")}.to raise_error(Leanback::CouchdbException)
        expect{ @model.get_monitor_events_by_type("my_monitor", "monitor.notification", {})}.to raise_error(Leanback::CouchdbException)
      end
      after(:each) do
        for count in 1..5 do
          @database.delete_doc! "notification_#{count}"
        end
      end
    end
    describe "#get_monitor_events" do
      before(:each) do
        for count in 1..5 do
          time = Time.now
          timestamp = time.to_i
          event = {
            monitor_id: "my_monitor",
            state: "failed",
            event: {winner: "chicken dinner"},
            time: time,
            timestamp: timestamp,
            monitor: {},
            event_type: "monitor.test",
            type: "event"
          }
          @database.create_doc  "event_#{count}", event
        end
      end
      it "returns all events for the monitor that happened within the specified date range" do
        events = @model.get_monitor_events("my_monitor", start_date: "3015-01-15 05:30:00 -0500", end_date: "1913-01-15 05:30:00 -0500")
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_1"
        events.count.should == 5

        events = @model.get_monitor_events("my_monitor", start_date: "3015-01-15 05:30:00", end_date: "1913-01-15 05:30:00")
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_1"
        events.count.should == 5

        events = @model.get_monitor_events("my_monitor", start_date: "3015-01-15", end_date: "1913-01-15")
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_1"
        events.count.should == 5

        events = @model.get_monitor_events("my_monitor", start_date: "3015-01-15", end_date: "1913-01-15")
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_1"
        events.count.should == 5

        events = @model.get_monitor_events("my_monitor", start_date: "3015", end_date: "1913")
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_1"
        events.count.should == 5
      end
      it "can limit the number of returned results" do
        events = @model.get_monitor_events("my_monitor", start_date: "3015", end_date: "1913", take: 2)
        events.first[:_id].should == "event_5"
        events.last[:_id].should == "event_4"
        events.count.should == 2
      end
      it "cannot return events with reversed or missing start and end date" do
        expect{ @model.get_monitor_events("my_monitor", end_date: "3015-01-15 05:30:00 -0500", start_date: "1913-01-15 05:30:00 -0500") }.to raise_error(Leanback::CouchdbException)
        expect{ @model.get_monitor_events("my_monitor", {}) }.to raise_error(Leanback::CouchdbException)
      end
      it "returns an empty array when no events happened in the provided data range" do
        @model.get_monitor_events("my_monitor", start_date: "1965", end_date: "1913").should == []
      end
      it "returns an empty array when the specified monitor is not found" do
        @model.get_monitor_events("not_found", start_date: "3015", end_date: "1913").should == []
      end
      after(:each) do
        for count in 1..5 do
          @database.delete_doc! "event_#{count}"
        end
      end
    end
    after(:each) do
      @database.delete_doc!("exists")
    end
  end
  after(:all) do
    @database.delete
  end
end
