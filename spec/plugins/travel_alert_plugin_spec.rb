require 'spec_base.rb'

options1 = { monitor: 'travel_alert',
             every: '10m',
             test: 'Monitor Travel alerts',
             location: 'usa',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }
		   
options2 =  { monitor: 'travel_alert',
             every: '10m',
             test: 'Monitor Travel alerts',
             location: 'Nigeria',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }

describe Monitors::TravelAlert do

 it "should not detect any travel alert for USA" do
    h = Monitors::TravelAlert.new
    h.init(options1) 
    h.test_command.should == TRUE
 end

 it "should detect a travel alert present for Nigeria" do 
    f = Monitors::TravelAlert.new
    f.init(options2)
    f.test_command.should ==  FALSE
 end 
end
