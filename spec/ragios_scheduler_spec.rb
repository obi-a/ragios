require 'spec_base.rb'

class URLMonitor < Ragios::Monitors::URL
   def initialize
       @time_interval = '20m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "sample URL test to http://google.com "
      @url = "http://google.com"
      super
   end
  
   def notify
     gmail_notify
  end

  def fixed
     gmail_resolved
  end
end

class HttpsMonitor < Ragios::Monitors::URL
   def initialize
       @time_interval = '20m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "sample https test"
      @url = "https://github.com/obi-a/Ragios"
      super
   end

   def notify
     puts 'gmail_notify'
  end

  def fixed
     gmail_resolved
  end

end


class FailedURLMonitor < Ragios::Monitors::URL
   def initialize
       @time_interval = '20m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description  = "sample Website that always fails"
      @url = "http://www.google.com/fail"
      super
   end

    def notify
     puts 'gmail_notify'
  end

  def fixed
     puts 'gmail_resolved'
  end

end

class HTTPMonitor < Ragios::Monitors::HTTP
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test"
      @describe_test_result = "sample test http to google.com"
      @domain = "google.com"
      super
   end
   
    def notify
     puts 'gmail_notify'
  end

  def fixed
     puts 'gmail_resolved'
  end

end

class FailedHTTPMonitor < Ragios::Monitors::HTTP
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test"
      @describe_test_result = "failed domain"
      @domain = "obiora-akubue.com"
      super
   end

    def notify
     puts 'gmail_notify'
  end

  def fixed
     puts 'gmail_resolved'
  end

end

class MonitorApache <  Ragios::Monitors::Process
    def initialize

      @time_interval = '1m'
      @notification_interval = '2m'
      @contact = "admin@mail.com"
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
     puts 'gmail_notify: Apache FAILED on host ' + @hostname
  end

  def fixed
    puts 'gmail_resolved: Apache is now WORKING again on host ' + @hostname 
  end

 end



class BadCodeMonitor < Ragios::Monitors::URL
   #a monitoring object with bad code that throws a runtime error
   def initialize
       @time_interval = '1m'
      @notification_interval = '2m'
      @contact = "obi@mail.com"
      @test_description  = "sample Website that always fails"
      @url = "http://www.google.com/fail"
      super
   end

    def test_command
     raise "bad code"
    end

   def error_handler
     puts 'bad code ALERT: error' 
   end

end


describe Ragios::Schedulers::RagiosScheduler do

    before(:each) do
   
     @ragios = Ragios::Schedulers::RagiosScheduler.new [
         URLMonitor.new, FailedURLMonitor.new,HttpsMonitor.new,HTTPMonitor.new,FailedHTTPMonitor.new, MonitorApache.new]
  end 
    

    it "should initalize all monitors and run their test command" do 
      @ragios.init
    end

    it "should recover when a monitor throws an exception" do 
       badlycoded = Ragios::Schedulers::RagiosScheduler.new [ BadCodeMonitor.new] 
       #badlycoded.start      
    end
    
    it "should schedule all monitors to run their tests at their specified time interval" do 
       @ragios.start
       monitors = @ragios.get_monitors   
       
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
