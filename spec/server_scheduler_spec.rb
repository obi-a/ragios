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
                   via: 'gmail',  
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
                   via: 'gmail',  
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
                   via: 'gmail',  
                   notify_interval:'3h',
                   _id: 'test_monitor'
                  }
        @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]      
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
                   via: 'gmail',  
                   notify_interval:'3h'
                  }

      doc = {:database => 'monitors', :doc_id => 'test_monitor', :data => data}
     begin
      Document.create doc
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
end
