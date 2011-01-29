require 'spec_base.rb'

    monitoring =  
		 { :monitor => 'url',
                   :every => '30s',
                   :test => 'github repo a http test',
                   :url => 'https://github.com/obi-a/Ragios',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',  
                   :notify_interval => '6h'
                  
                  },

		   {:monitor =>'http',
                   :every => '2m',
                   :test => 'Http connection to my blog',
                   :domain => 'obi-akubue.org',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',  
                   :notify_interval => '6h'
                  } ,
                  { :monitor => 'url',
                   :every => '2m',
                   :test => 'My Website Test',
                   :url => 'http://www.whisperservers.com/blog/',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',  
                   :notify_interval => '6h'
                  
                  },
                  { :monitor => 'process',
                   :every => '1m',
                   :test => 'Apache Test',
                   :process_name => 'apache2',
                   :start_command => 'sudo /etc/init.d/apache2 start',
                   :stop_command => 'sudo /etc/init.d/apache2 stop',
                   :restart_command => 'sudo /etc/init.d/apache2 restart',
                   :pid_file => '/var/run/apache2.pid',
                   :server_alias => 'my home server',
                   :hostname => '192.168.2.9',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',  
                   :notify_interval => '2m'
                  }

 describe Ragios::Monitor do 

   it "should schedule all monitors to run the definded tests at their specified intervals" do 
        monitors = Ragios::Monitor.start monitoring

     monitors.each do |monitor|  
         monitor.num_tests_failed.should == 0
         monitor.num_tests_passed.should == 0
         monitor.total_num_tests.should == 0
         puts monitor.test_description 
         puts monitor.creation_date
         puts monitor.time_of_last_test
     end
        
   end
  
 end

