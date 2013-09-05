require 'spec_base.rb'

options1 = { monitor: 'http',
             every: '10m',
             test: 'google site test',
             domain: 'www.google.com',
             contact: 'admin@mail.com',
             via: 'gmail',  
             notify_interval: '6h'
             }
		   
options2 =  { monitor: 'http',
              every: '2m',
              test: 'domain doesnt exist',
              domain: 'southmunn.n',
              contact: 'admin@mail.com',
              via: 'gmail',  
              notify_interval: '6h'
             }

describe Ragios::Monitors::Http do

 it "should establish a http connection with google.com" do
    h = Ragios::Monitors::Http.new
    h.init(options1) 
    h.test_command.should == TRUE
 end

 it "should fail to establish a http connection" do 
    f = Ragios::Monitors::Http.new
    f.init(options2)
    f.test_command.should ==  FALSE
 end 
end
