  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  
  dir = Pathname(__FILE__).dirname.expand_path
  require dir + 'lib/ragios'

  #Add your code here

 monitoring   = { monitor: 'http',
                  every: '5m',
                  test: 'Http connection to my site',
                  domain: 'www.google.com',
                  contact: 'admin@mysite.com',
                   via: 'gmail',
                   notify_interval: '6h'
                  },
                 { monitor: 'url',
                   every: '5m',
                   test: 'video datafeed test',
                   url: 'http://www.google.com',
                   contact: 'admin@mail.com',
                   via: 'gmail',
                   notify_interval: => '6h'
                  }
                   
  Ragios::Monitor.start monitoring

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
