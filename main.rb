  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"

  require 'lib/ragios'



  class MonitorMySite < Ragios::Monitors::HTTP
    def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "Http connection to my blog"
      @domain = "obi-akubue.org"
      super
    end

    def notify
      email_notify
      #gmail_notify
      #tweet_notify
    end

  end


  class MonitorBlogURL <  Ragios::Monitors::URL
    def initialize
      @time_interval = '20m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "My Website Test"
      @url = "http://www.whisperservers.com/blog/"
      super
    end

   def notify
     email_notify
     #gmail_notify
     #tweet_notify
   end

  end
 
class MonitorApache <  Ragios::Monitors::Process
    def initialize
       
      @time_interval = '1m'
      @notification_interval = '2m'
      @contact = "obi.akubue@gmail.com"
      @test_description  = "Apache Test" 
      
      @process_name = 'apache2'
      @start_command = 'sudo /etc/init.d/apache2 start'
      @restart_command = 'sudo /etc/init.d/apache2 restart'
      @stop_command = 'sudo /etc/init.d/apache2 stop'
      @pid_file = '/var/run/apache2.pid'
     
      @server_alias = 'my home server'
      @hostname = '192.168.2.2'
 
      super
    end

   def notify
     #email_notify
     gmail_notify
     #tweet_notify
  end

  def fixed 
     gmail_resolved
  end

end


  monitoring = [MonitorApache.new]
  
  ragios = Ragios::System.new 
  ragios.start monitoring



