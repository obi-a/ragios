require 'spec_base.rb'

describe Ragios::Notifier::Ses do
    it "should send a notification message via ses" do
         message = {:to => "obi.akubue@gmail.com",
                    :subject =>"Test notification message from Ragios via ses", 
                     :body => "stuff"}
   
      Ragios::Notifier::Ses.new.deliver message
   end
end

describe Ragios::Controller do
   it "should create a generic monitor and send a notification messages (FAILED/FIXED) via ses" do
       monitors = [{ tag: 'test',
                   monitor: 'url',
                   every: '1m',
                   test: 'Generic monitor test notification',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@gmail.com',
                   via: 'ses',  
                   notify_interval: '6h'
                    }]

     Ragios::Controller.scheduler(Ragios::Schedulers::Server.new)

     monitors =  Ragios::Controller.add_monitors(monitors)
     #verify that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor
     monitors[0].notify
     monitors[0].fixed
   end
end
