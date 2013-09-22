require 'spec_base.rb'

describe Ragios::Controller do

 it "should initialize all monitors on ragios core and activate the core scheduler" do 


  list_of_monitors = { tag: 'admin',
                 monitor: 'url',
                   every: '1h',
                   test: '1 test feed',
                   url: 'http://obi-akubue.org',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval: '6h'
                    },
                  { tag: 'obi', 
                   monitor: 'url',
                   every: '1h',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail_notifier',  
                   notify_interval:'3h'
                  }

     #options = {core_scheduler: Ragios::Schedulers::RagiosScheduler.new}
     #Ragios::Controller.init(options)

     @monitors = Ragios::Controller.run_monitors(list_of_monitors)
     @monitors.each do |monitor|  
         monitor.total_num_tests.should == 1
         puts monitor.test_description 
         puts monitor.creation_date
         puts monitor.time_of_last_test
     end
    
 end
end






