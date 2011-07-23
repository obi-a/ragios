  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
  require  Pathname(__FILE__).dirname.expand_path + 'config' 

  require 'yajl'

 #Add your code here

  monitoring = { tag: 'admin',
                 monitor: 'url',
                   every: '1m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval: '6h'
                    },
                  { tag: 'obi', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3m'
                  }
  #Ragios::Monitor.start monitoring
  #Ragios::Monitor.start monitoring,server=TRUE
 # Ragios::Monitor.restart
   
  Ragios::Server.stop_monitor(id ='')
  
  Ragios::Server.restart_monitor(id ='')
  Ragios::Server.delete_monitor(id ='')
  

  #hash = Ragios::Server.find_monitors(:contact => 'obi.akubue@mail.com')
  #hash = Ragios::Server.find_monitors(:monitor => 'url')
  #hash = Ragios::Server.find_stats(:every => '1m')
  #hash = Ragios::Server.find_monitors(:tag => 'admin')
  #hash = Ragios::Server.find_stats(:tag => 'admin')
   #hash = Ragios::Monitor.restart
   #puts hash.inspect

  #puts Ragios::Server.status_report(tag = "admin")
  #puts Ragios::Server.status_report


  config = {   :every => '1m',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                  :tag => 'admin' 
                  }
    

  #Ragios::Server.start_status_update(config)
  #Ragios::Server.restart_status_updates('admin')
  #Ragios::Server.stop_status_update('admin')
  #Ragios::Server.delete_status_update('admin')

  

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
