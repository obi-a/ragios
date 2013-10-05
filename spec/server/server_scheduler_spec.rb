require 'spec_base.rb'


class Monitor1 < Ragios::Monitors::System
  attr_accessor :id
  attr_reader :options

   def initialize

      @options = { tag: 'test',
                 monitor: 'url',
                   every: '87m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h',
                   _id: 'runtime_id'
                    }
         @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]
   end 
end


class Monitor2 < Ragios::Monitors::System
 attr_accessor :id
 attr_reader :options
   def initialize
      @options = { tag: 'test', 
                   monitor: 'url',
                   every: '88m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h',
                   _id: 'runtime_id'
                  }
        @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]
        
      
   end 
end

class Monitor3 < Ragios::Monitors::System
 attr_accessor :id
 attr_reader :options
   def initialize
      @options = { tag: 'test', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h',
                   _id: 'test_monitor'
                  }
        @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]      
   end 
end

class Monitor4 < Ragios::Monitors::System
  attr_accessor :id
  attr_reader :options
  def initialize
    @options = { tag: 'something', 
                   monitor: 'url',
                   every: '1h',
                   test: 'Great test to somewhere',
                   url: 'http://o-b-i-akubue.com',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h',
                   _id: 'test-2-somewhere'
                  }
    @time_interval = @options[:every]
    @notification_interval = @options[:notify_interval]
    @contact = @options[:contact]
    @test_description = @options[:test]  
    @describe_test_result = ""  
    @id = @options[:_id]
    super
  end 

  def test_command
    @test_result = "GOOD"
    TRUE
  end
end

describe Ragios::Schedulers::Server do
    it "should create new monitors and store in the database" do 
      @ragios = Ragios::Schedulers::Server.new 
      @ragios.create [Monitor1.new, Monitor2.new] 
    end
 
    it "should start monitoring new monitors" do 
      @ragios = Ragios::Schedulers::Server.new 
      @ragios.create [Monitor1.new, Monitor2.new] 
      @ragios.start
    end
    
    it "should restart monitors" do
      @ragios = Ragios::Schedulers::Server.new 
      @ragios.restart [Monitor1.new, Monitor2.new] 
      sch = @ragios.get_monitors('runtime_id')
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].t.should == "87m"
      sch[1].class.should ==  Rufus::Scheduler::EveryJob
      sch[1].t.should == "88m"
    end

    it "should stop a monitor" do

      data = { tag: 'test', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h'
                  }

      doc = {:database => Ragios::CouchdbAdmin.monitors, :doc_id => 'test_monitor', :data => data}
     begin
      Couchdb.create_doc doc,Ragios::CouchdbAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

      @ragios = Ragios::Schedulers::Server.new 
      @ragios.restart [Monitor1.new, Monitor2.new, Monitor3.new]

      sch = @ragios.get_monitors('test_monitor')
      sch[0].class.should ==  Rufus::Scheduler::EveryJob
      sch[0].params[:tags].should == ["test_monitor"]

      @ragios.stop_monitor('test_monitor')
      @ragios.get_monitors('test_monitor').should == []
      
    end      

    it "should verify that task was done and the activity was logged" do
       #add the monitor to DB
       data = { monitor: 'url',
                   every: '1h',
                   test: 'Great test to somewhere',
                   url: 'http://o-b-i-akubue.com',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h'
                  }

      doc = {:database => Ragios::CouchdbAdmin.monitors, :doc_id => 'test-2-somewhere', :data => data}
     begin
      Couchdb.create_doc doc,Ragios::CouchdbAdmin.session
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 
      #start the same monitor as a class
      @ragios = Ragios::Schedulers::Server.new  
      @ragios.do_task(Monitor4.new)

      #The running monitor should match the logged activity information
      doc = {:database => Ragios::CouchdbAdmin.monitors, :doc_id => 'test-2-somewhere'}
      hash = Couchdb.view doc,Ragios::CouchdbAdmin.session

      keys = {:time_of_test => hash["time_of_last_test"],:monitor_id => 'test-2-somewhere'}
      activities = Couchdb.find_by_keys({:database => Ragios::CouchdbAdmin.activity_log, :keys => keys},Ragios::CouchdbAdmin.session)
      activity = activities[0]

      #proof that the task was excuted
      hash["status"].should == "UP"
      activity["status"].should == "UP"
      hash["last_test_result"].should == "GOOD"
      activity["test_result"].should == "GOOD"
      
      #Proof that the activity was logged
      hash["time_of_last_test"].should == activity["time_of_test"]
      hash["_id"].should == activity["monitor_id"]
      
      #clean up
      doc = {:database => Ragios::CouchdbAdmin.monitors, :doc_id => 'test-2-somewhere'}
      Couchdb.delete_doc doc,Ragios::CouchdbAdmin.session
    end
end
