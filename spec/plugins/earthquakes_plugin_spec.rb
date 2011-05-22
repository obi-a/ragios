require 'spec_base.rb'

options1 = { monitor: 'earthquakes',
             every: '10m',
             test: 'Monitor new york for earthquakes ',
             location: 'new york',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }
		   
options2 =   { monitor: 'earthquakes',
             every: '10m',
             test: 'Monitor mexico for earthquakes ',
             location: 'mexico',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }

describe Monitors::Earthquakes do

 it "should not detect an earthquake in New York" do
    h = Monitors::Earthquakes.new
    h.init(options1) 
    h.test_command.should == TRUE
 end

 it "should detect earthquakes that happened in California over the last 7 days" do 
    f = Monitors::Earthquakes.new
    f.init(options2)
    f.test_command.should ==  FALSE
    #f.notify
 end 
end
