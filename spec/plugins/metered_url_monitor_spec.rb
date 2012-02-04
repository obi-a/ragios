require 'spec_base.rb'

#testing a https url
https_options = { monitor: 'metered_url_monitor',
             every: '30s',
             test: 'github repo a http test',
             url: 'https://github.com/obi-a/Ragios',
             contact: 'obi.akubue@mail.com',
             via: 'gmail',  
             notify_interval:'6h',
            tag: 'obi'  
            }

#testing a regular url 
regular_url_options =  { monitor: 'metered_url_monitor',
              every: '5m',
              test: 'google site test',
              url: 'http://www.google.com',
              contact: 'admin@mail.com',
              via: 'gmail',
              notify_interval: '6h',
              tag: 'obi'
            }

#testing a fake url
fake_url_options  = { monitor: 'metered_url_monitor',
              every: '2m',
              test: 'fake url test',
              url: 'http://www.google.com/fail/',
              contact: 'obi.akubue@mail.com',
              via: 'gmail',  
              notify_interval: '6h',
              tag: 'ace'
             }

describe Monitors::MeteredUrlMonitor do

 it "should send a http GET request to the url in options and pass" do
    r = Monitors::MeteredUrlMonitor.new
    r.init(regular_url_options)
    r.log
    #r.test_command.should == TRUE
 end

 it "should send a http GET request to the url in options and fail" do 
    f = Monitors::MeteredUrlMonitor.new
    f.init(fake_url_options)
    f.test_command.should ==  FALSE
 end 

 it "should send a https GET request to the url in options and pass" do 
    s = Monitors::MeteredUrlMonitor.new
    s.init(https_options)
    s.test_command.should == TRUE
 end

end
