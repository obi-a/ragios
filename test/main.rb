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
                   notify_interval:'3h'
                  }
  #Ragios::Monitor.start monitoring
  
  #Ragios::Server.init
  #Ragios::Monitor.start monitoring,server=TRUE
  #Ragios::Monitor.restart
  #sch = Ragios::Server.get_monitors_frm_scheduler
  #puts sch.inspect

  #Ragios::Monitor.restart

  #restart a stopped monitor while server is still running
  #Ragios::Monitor.restart(id = 'a62e051e-46dc-437a-90af-965577444884')
   
  #hash = Ragios::Server.get_active_monitors
  #hash = Ragios::Server.get_stopped_status_updates('admin')
  #hash = Ragios::Server.get_active_status_updates

  #TODO
  #hash = Ragios::Server.stop_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  #Ragios::Server.restart_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  #hash = Ragios::Server.delete_monitor(id ='f9663c34-533f-4a27-b04e-b6d54cd7a870')
  #hash = Ragios::Server.delete_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  

  #hash = Ragios::Server.find_monitors(:contact => 'obi.akubue@mail.com')
  #hash = Ragios::Server.find_monitors(:monitor => 'url')
  #hash = Ragios::Server.find_monitors(:every => '1m')
  #hash = Ragios::Server.find_monitors(:tag => 'admin')
  
  

  #puts Ragios::Server.status_report(tag = "admin")
  #puts Ragios::Server.status_report


  config = {   :every => '1m',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                  :tag => 'obi' 
                  }
    

  #Ragios::Server.start_status_update(config)
  #Ragios::Server.restart_status_updates('admin')

   #this should be run with a server restart
   Ragios::Server.init
   #Ragios::Server.restart_status_updates
    #sch = Ragios::Server.get_status_update_frm_scheduler
    #puts sch.inspect
   #hash = Ragios::Server.stop_status_update('admin')
  #Ragios::Server.delete_status_update('admin')
   #  
   data = {   :every => '8m',
                   :contact => 'obi@gmail.com',
                   :via => 'email'
                  }
    id = "sample_status_update"
  hash =  Ragios::Server.edit_status_update(id,data)

   data  = {    monitor: 'url',
                   every: '5m',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail'
                  }
  # id = "16b2ae38-9116-438c-9c5e-ab743e4edc79"
 # Ragios::Server.update_monitor(id,data)

#puts hash.inspect

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
