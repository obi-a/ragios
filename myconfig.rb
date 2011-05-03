  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  
  dir = Pathname(__FILE__).dirname.expand_path
  require dir + 'lib/ragios'

  #Add your code here

 monitoring   = {:monitor =>'http',
                   :every => '5m',
                   :test => 'Http connection to my site',
                   :domain => 'www.google.com',
                   :contact => 'admin@mysite.com',
                   :via => 'gmail',
                   :notify_interval => '6h'
                  },
                   { :monitor => 'url',
                   :every => '5m',
                   :test => 'video datafeed test',
                   :url => 'http://www.google.com',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                   :notify_interval => '6h'
                  },
                  {  :monitor => 'process',
                   :every => '5m',
                   :test => 'Apache Test',
                   :process_name => 'apache2',
                   :start_command => '/etc/init.d/apache2 start',
                   :stop_command => '/etc/init.d/apache2 stop',
                   :restart_command => '/etc/init.d/apache2 restart',
                   :pid_file => '/var/run/apache2.pid',
                   :server_alias => 'my home server',
                   :hostname => '192.168.2.9',
                   :contact => 'obi.akubue@mail.com',
                   :via => 'gmail',
                   :notify_interval => '2m'
                  }
                   
  Ragios::Monitor.start monitoring

 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
