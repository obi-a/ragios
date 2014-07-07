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
    after(:each) do
      @database.delete_doc!("exists")
    end
  end
  after(:all) do
    @database.delete
  end
end