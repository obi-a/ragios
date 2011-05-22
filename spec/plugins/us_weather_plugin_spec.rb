require 'spec_base.rb'

options1 = { monitor: 'us_weather',
             every: '10m',
             test: 'Monitor a county in the US for extreme weather alerts or predictions',
             county: 'bronx',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }
		   
options2 =   { monitor: 'us_weather',
             every: '10m',
             test: 'Monitor white county AK for extreme',
             county: 'white county',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }

describe Monitors::UsWeather do

 it "should not detect extreme weather alerts for Bronx,NY " do
    h = Monitors::UsWeather.new
    h.init(options1) 
    h.test_command.should == TRUE
 end

 it "should detect weather alerts for White County AK" do 
    f = Monitors::UsWeather.new
    f.init(options2)
    f.test_command.should ==  FALSE
    #f.notify
 end 
end
