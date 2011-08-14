require 'spec_base.rb'


class Monitor1 < Ragios::Monitors::System
  attr_accessor :id
  attr_reader :options

   def initialize

      @options = { tag: 'admin',
                 monitor: 'url',
                   every: '1m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval: '6h'
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
      @options = { tag: 'obi', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h'
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
      @options = { tag: 'obi', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h'
                  }
        @time_interval = @options[:every]
        @notification_interval = @options[:notify_interval]
        @contact = @options[:contact]
        @test_description = @options[:test]
        @id = "test_monitor"
        
      
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
    end

    it "should stop a monitor" do

      data = { tag: 'obi', 
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
       puts "Error message: " + e.to_s
     end 

      @ragios = Ragios::Schedulers::Server.new 
      @ragios.restart [Monitor1.new, Monitor2.new]
      @ragios.stop_monitor('test_monitor')
    end

    
        
end
