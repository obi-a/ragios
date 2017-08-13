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
    @database.create_doc("exists", name: "some document")
  end
  describe "basic database operatons" do
    describe "#save" do
      context "when document doesn't already exists" do
        it "saves the document" do
          doc_id = "linda{Time.now.to_i}"
          options = {name: "ragios"}
          results = @model.save(doc_id, options)
          expect(results).to include(ok: true, id: doc_id)
        end
      end
      context "when document already exists" do
        it "raises a CouchDB exception" do
          expect { @model.save("exists", something: "something") }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    describe "#find" do
      context "when document with provided id exists" do
        it "returns the document" do
          doc = @model.find("exists")
          expect(doc).to include(_id: "exists", name: "some document")
        end
      end
      context "when document with provided id does not exist" do
        it "raises a Leanback::CouchdbException error" do
          expect { @model.find("dont_exist") }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    describe "#update" do
      context "when document exists" do
        it "updates the document with provided id"  do
          results = @model.update("exists", name: "a change")
          expect(results).to include(ok: true, id: "exists")
        end
      end
      context "when document does not exist" do
        it "raises a Leanback::CouchdbException exception" do
          expect { @model.update("dont_exists", name: "a change", other: nil, number: 1) }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    describe "#delete" do
      context "when document exists" do
        it "deletes the document" do
          @model.save("john", name: "ragios")
          results = @model.delete("john")
          expect(results).to include(ok: true, id: "john")
        end
      end
      context "when document doesnt exist" do
        it "raise a Leanback::CouchdbException exception" do
          expect{ @model.delete("dont_exist") }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
  end
  describe "monitors data" do
    context "when monitors are in the database" do
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
      describe "#active_monitors" do
        it "returns all monitors with status_ active" do
          expect(@model.active_monitors.first).to include(_id: "monitor_3")
          expect(@model.active_monitors.count).to eq(1)
        end

        it "can limit results" do
          expect(@model.active_monitors(limit: 1).count).to eq(1)
        end
      end
      describe "#all_monitors" do
        it "returns all monitors ordered by document_date monitor[:created_at_]" do
          expect(@model.all_monitors.first).to include(_id: "monitor_3")
          expect(@model.all_monitors.last).to include(_id: "monitor_1")
        end
        it "can limit results" do
          expect(@model.all_monitors(limit: 2).count).to eq(2)
        end
      end
      describe "#monitors_where" do
        it "returns monitors that match provided attributes" do
          expect(@model.monitors_where(status_: "active").first).to include(_id: "monitor_3")
        end
        it "can limit results" do
          expect(@model.monitors_where({status_: "stopped"}, limit: 1).count).to eq(1)
        end
        it "returns an empty array when no attributes match" do
          expect(@model.monitors_where(monitor: "doesn't exist")).to eq([])
        end
        it "Returns an empty array when key doesnt exist" do
          expect(@model.monitors_where(dont_exist: "doesn't exist")).to eq([])
        end
      end
      after(:each) do
        for count in 1..3 do
          @database.delete_doc! "monitor_#{count}"
        end
      end
    end
    context "when there is no monitor  in the database" do
      describe "#active_monitors" do
        it "returns an empty array" do
          expect(@model.active_monitors).to eq([])
        end
      end
      describe "#all_monitors" do
        it "returns an empty array" do
          expect(@model.all_monitors).to eq([])
        end
      end
      describe "#monitors_where" do
        it "returns an empty array" do
          expect(@model.monitors_where(status_: "active")).to eq([])
        end
      end
    end
  end
  describe "#get_monitor_state" do
    context "when monitor has no test_result" do
      it "returns an empty hash" do
        expect(@model.get_monitor_state("no_test_result")).to eq({})
      end
    end
    context "when monitor has no test_results" do
      before(:each) do
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
        @latest_timestamp = time.to_i
        latest_test_result = {
          monitor_id: "my_monitor",
          state: "failed",
          event: {winner: "chicken dinner"},
          time: latest_time,
          timestamp: @latest_timestamp,
          monitor: {},
          event_type: "monitor.test",
          type: "event"
        }
        @database.create_doc "latest_activity", latest_test_result
      end
      it "returns monitors current state" do
        expect(@model.get_monitor_state("my_monitor")).to include(_id: "latest_activity", timestamp: @latest_timestamp)
      end
      after(:each) do
        for count in 1..5 do
          @database.delete_doc! "activity#{count}"
        end
        @database.delete_doc! "latest_activity"
      end
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

    context "when the monitor exists" do
      context "when monitor has events in the provided state" do
        context "when events occurred in the provided date range" do
          it "returns the events ordered by the latest first" do
            events = @model.get_monitor_events_by_state("my_monitor", "failed", start_date: "3015-01-15 05:30:00 -0500", end_date: "1913")
            expect(events.first[:_id]).to eq("event_by_state_5")
            expect(events.last[:_id]).to eq("event_by_state_1")
            expect(events.count).to eq(5)
          end
          it "can limit the events it returns" do
            events = @model.get_monitor_events_by_state("my_monitor", "failed", start_date: "3015", end_date: "1913", limit: 2)
            expect(events.first[:_id]).to eq("event_by_state_5")
            expect(events.last[:_id]).to eq("event_by_state_4")
            expect(events.count).to eq(2)
          end
        end
        context "when daterange is provided in a bad range start_date older than end_date" do
          it "raises a Leanback::CouchdbException error" do
            expect{@model.get_monitor_events_by_state("my_monitor", "failed", start_date: "1913", end_date: "3015")}.to raise_error(
              Leanback::CouchdbException
            )
          end
        end
        context "when no events occurred in the provided daterange" do
          it "returns no events" do
            expect(@model.get_monitor_events_by_state("my_monitor", "failed", start_date: "1960", end_date: "1913")).to eq([])
          end
        end
      end
      context "when monitor has no events in the provided state" do
        it "returns no events" do
          expect(@model.get_monitor_events_by_state("my_monitor", "passed", start_date: "3015", end_date: "1913")).to eq([])
        end
      end
      context "when options are not provided" do
        it "raises a Leanback::CouchdbException error" do
         expect { @model.get_monitor_events_by_state("my_monitor", "failed", {}) }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    context "when the monitor doesn't exist" do
      it "returns no events" do
        expect(@model.get_monitor_events_by_state("not_found", "failed", start_date: "3015", end_date: "1925")).to eq([])
      end
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

    context "when the monitor exists" do
      context "when monitor has events in the provided event_type" do
        context "when events occurred in the provided date range" do
          it "returns the events ordered by the latest first" do
            notifications = @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "3015", end_date: "1913")
            expect(notifications.first[:_id]).to  eq("notification_5")
            expect(notifications.last[:_id]).to eq("notification_1")
            expect(notifications.count).to eq(5)
          end
          it "can limit the events it returns" do
            notifications = @model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "3015", end_date: "1913", limit: 2)
            expect(notifications.first[:_id]).to eq("notification_5")
            expect(notifications.last[:_id]).to eq("notification_4")
            expect(notifications.count).to eq(2)
          end
        end
        context "when daterange is provided in a bad range start_date older than end_date" do
          it "raises a Leanback::CouchdbException exception" do
            expect{@model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "1913", end_date: "3015")}.to raise_error(
              Leanback::CouchdbException
            )
          end
        end
        context "when no events occurred in the provided daterange" do
          it "returns no events" do
            expect(@model.get_monitor_events_by_type("my_monitor", "monitor.notification", start_date: "1960", end_date: "1925")).to eq([])
          end
        end
      end
      context "when monitor has no events in the provided event_type" do
        it "returns no events" do
          expect(@model.get_monitor_events_by_type("my_monitor", "monitor.triggered", start_date: "3015", end_date: "1925")).to eq([])
        end
      end
      context "when options are not provided" do
        it "raises a Leanback::CouchdbException error" do
          expect{@model.get_monitor_events_by_type("my_monitor", "monitor.triggered", {})}.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    context "when the monitor doesn't exist" do
      it "returns no events" do
        expect(@model.get_monitor_events_by_type("not_found", "monitor.notification", start_date: "3015", end_date: "1913")).to eq([])
      end
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

    context "when the monitor exists" do
      context "when monitor has events" do
        context "when events occurred in the provided date range" do
          it "returns the events ordered by the latest first" do
            events = @model.get_monitor_events("my_monitor", start_date: "3015-01-15 05:30:00 -0500", end_date: "1913-01-15 05:30:00 -0500")
            expect(events.first[:_id]).to eq("event_5")
            expect(events.last[:_id]).to eq("event_1")
            expect(events.count).to eq(5)
          end
          it "can limit the events it returns" do
            events = @model.get_monitor_events("my_monitor", start_date: "3015", end_date: "1913", limit: 2)
            expect(events.first[:_id]).to eq("event_5")
            expect(events.last[:_id]).to eq("event_4")
            expect(events.count).to eq(2)
          end
        end
        context "when daterange is provided in a bad range start_date older than end_date" do
          it "raises a Leanback::CouchdbException exception" do
            expect{@model.get_monitor_events("my_monitor", start_date: "1913", end_date: "3015")}.to raise_error(
              Leanback::CouchdbException
            )
          end
        end
        context "when no events occurred in the provided daterange" do
          it "returns no events" do
            expect(@model.get_monitor_events("my_monitor", start_date: "1960", end_date: "1925")).to eq([])
          end
        end
      end
      context "when monitor has no events" do
        it "returns no events" do
          some_monitor_id = "some_monitor#{Time.now.to_i}"
          @database.create_doc(some_monitor_id, monitor: "some monitor", type: "monitor")
          expect(@model.get_monitor_events(some_monitor_id, start_date: "3015", end_date: "1913")).to eq([])
          @database.delete_doc! some_monitor_id
        end
      end
      context "when options are not provided" do
        it "raises a Leanback::CouchdbException error" do
          expect{ @model.get_monitor_events("my_monitor", {}) }.to raise_error(Leanback::CouchdbException)
        end
      end
    end
    context "when the monitor doesn't exist" do
      it "returns no events" do
        expect(@model.get_monitor_events("not_found", start_date: "3015", end_date: "1913")).to eq([])
      end
    end
    after(:each) do
      for count in 1..5 do
        @database.delete_doc! "event_#{count}"
      end
    end
  end

  after(:all) do
    @database.delete
  end
end