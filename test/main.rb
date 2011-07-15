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
  Ragios::Monitor.start monitoring,server=TRUE
  #Ragios::Monitor.restart

  #hash = Ragios::Server.find_monitors(:contact => 'obi.akubue@mail.com')
  #hash = Ragios::Server.find_monitors(:monitor => 'url')
  #hash = Ragios::Server.find_stats(:every => '1m')
  #hash = Ragios::Server.find_monitors(:tag => 'admin')
  #hash = Ragios::Server.find_stats(:tag => 'admin')
   #hash = Ragios::Monitor.restart
   #puts hash.inspect
  

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
