#working on a Domain specific language for Ragios
#ragios/main.rb
  require 'rubygems'
  require "bundler/setup"

  require 'lib/ragios'
    

     monitoring = {:monitoring =>'http',
                   :every => '10m',
                   :test => 'Http connection to my blog',
                   :domain => 'obi-akubue.org',
                   :contact => 'obi@mail.com',
                   :via => 'email',  
                   :notify_interval => '6h'
                  } ,
                  { :monitoring => 'url',
                   :every => '20m',
                   :test => 'My Website Test',
                   :url => 'http://www.whisperservers.com/blog/',
                   :contact => 'obi@mail.com',
                   :via => 'gmail',  
                   :notify_interval => '6h'
                  
                  },
                  {  :monitoring => 'process',
                   :every => '20m',
                   :test => 'Test if Apache is running',
                   :process_name => 'apache2',
                   :start_command => 'sudo /etc/init.d/apache2 start',
                   :stop_command => 'sudo /etc/init.d/apache2 stop',
                   :restart_command => 'sudo /etc/init.d/apache2 restart',
                   :pid_file => '/var/run/apache2.pid',
                   :server_alias => 'my home server'
                   :contact => 'obi@mail.com',
                   :via => 'twitter',  
                   :notify_interval => '6h'
                  }

  ragios = Ragios::Monitor.new 
  ragios.start monitoring




