  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
  require  Pathname(__FILE__).dirname.expand_path + 'config' 

 #Add your code here
 run_when_failed = lambda{ 
                            puts 'switch to backup datafeed'
                            puts 'do something'
                           }
 
  run_on_fixed = lambda{
                         puts 'switch back to main datafeed'
                         puts 'fixed'
                       }

  monitoring = { monitor: 'url',
                   every: '1m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval: '6h',
                   failed:run_when_failed, 
                   fixed:run_on_fixed  
                    },
                  { monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3m',
                   failed:run_when_failed, 
                   fixed:run_on_fixed 
                  }

  Ragios::Monitor.start monitoring


   monitoring = { monitor: 'url',
                   every: '1m',
                   test: '3 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval: '6h',
                   failed:run_when_failed, 
                   fixed:run_on_fixed  
                    },
                  { monitor: 'url',
                   every: '1m',
                   test: '4 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3m',
                   failed:run_when_failed, 
                   fixed:run_on_fixed 
                  }

  monitors = Ragios::Monitor.start monitoring
       
      monitors.each do |monitor|  
         puts monitor.test_description 
         puts monitor.creation_date
         puts monitor.time_of_last_test
      end

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
