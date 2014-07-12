require 'spec_base.rb'

#database configuration
database_admin = {login: {username: ENV['COUCHDB_ADMIN_USERNAME'], password: ENV['COUCHDB_ADMIN_PASSWORD'] },
                    database: 'ragios_test_model_database',
                    couchdb:  {address: 'http://localhost', port:'5984'}
                 }

Ragios::CouchdbAdmin.config(database_admin)

describe "Ragios::Database::Model" do
  before(:all) do
    @database = Leanback::Couchdb.new(database: "ragios_test_model_database#{Time.now.to_i}",
                  address: "http://localhost",
                  username: ENV['COUCHDB_ADMIN_USERNAME'],
                  password: ENV['COUCHDB_ADMIN_PASSWORD'],
                  port: "5984")
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
      it "document id must be a string" do
        expect { @model.save(1, something: "something") }.to raise_error(Leanback::InvalidDocumentID)
        expect { @model.save(:test, something: "something") }.to raise_error(Leanback::InvalidDocumentID)
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
          }
          @database.create_doc "monitor_#{count}", monitor

          other_monitor = {
            monitor: "website 3",
            every:  "3m",
            type: "monitor",
            status_: "active",
          }
        end
        @database.create_doc "monitor_3", other_monitor
      end
      describe "#all_monitors" do
        it "returns all monitors" do
          @model.all_monitors.first.should include(_id: "monitor_1")
          @model.all_monitors.last.should include(_id: "monitor_3")
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
        @model.get_monitor_state("no_test_result").should == nil
      end
      it "returns monitors current state" do
        for count in 1..5 do
          time = Time.now
          timestamp = time.to_i
          test_result = {
            monitor_id: "my_monitor",
            state: "failed",
            test_result: {winner: "chicken dinner"},
            time_of_test: time,
            timestamp_of_test: timestamp,
            monitor: {},
            type: "test_result"
          }
          @database.create_doc  "activity#{count}", test_result
        end
        latest_time = Time.now
        latest_timestamp = time.to_i
        latest_test_result = {
          monitor_id: "my_monitor",
          state: "failed",
          test_result: {winner: "chicken dinner"},
          time_of_test: latest_time,
          timestamp_of_test: latest_timestamp,
          monitor: {},
          type: "test_result"
        }
        @database.create_doc "latest_activity", latest_test_result

        @model.get_monitor_state("my_monitor").should include(_id: "latest_activity", timestamp_of_test: latest_timestamp)

        for count in 1..5 do
          @database.delete_doc! "activity#{count}"
        end
        @database.delete_doc! "latest_activity"
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
