require 'spec_base.rb'

describe Ragios::Notifier::TwitterNotifier do
 
  it "should send a tweet a notification message " do

       Ragios::Notifier::TwitterNotifier.new.tweet "Test notification message from Ragios via twitter. " + "Created on: " + Time.now.to_s
  end


  describe Ragios::Controller do
   it "should create a generic monitor and tweet notification messages for (FAILED/FIXED)" do
       monitors = [{ tag: 'test',
                   monitor: 'url',
                   every: '1m',
                   test: 'Generic monitor test notification',
                   url: 'http://www.google.com',
                   via: 'twitter_notifier',  
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

end
