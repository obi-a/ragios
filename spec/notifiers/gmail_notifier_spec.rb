require 'spec_base.rb'

describe Ragios::Notifier::GmailNotifier do
    it "should send a notification message via gmail" do
         message = {:to => "obi.akubue@gmail.com",
                    :subject =>"Test notification message from Ragios via gmail", 
                     :body => "stuff"}
   
      Ragios::Notifier::GmailNotifier.new.deliver message
   end
end

describe Ragios::Controller do
   it "should create a generic monitor and send a notification messages (FAILED/FIXED) via gmail" do
       monitoring = [{ tag: 'test',
                   monitor: 'url',
                   every: '1m',
                   test: 'Generic monitor test notification',
                   url: 'http://www.google.com',
                   contact: 'obi.akubue@gmail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h'
                    }]
     Ragios::Server.init
     monitors =  Ragios::Controller.add_monitors(monitoring)
     #verify that the generic monitor was properly created
     monitors[0].class.should == Ragios::GenericMonitor
     monitors[0].notify
     monitors[0].fixed
   end
end
