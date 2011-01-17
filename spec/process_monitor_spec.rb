require 'spec_base.rb'

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
  end


  class MonitorApacheUnknown <  Ragios::Monitors::Process
    def initialize

      @time_interval = '1m'
      @notification_interval = '2m'
      @contact = "admin@mail.com"
      @test_description  = "Apache Unknown Test: this test always fails"

      @process_name = 'apache90'
      @start_command = 'sudo /etc/init.d/apache90 start'
      @restart_command = 'sudo /etc/init.d/apache90 restart'
      @stop_command = 'sudo /etc/init.d/apache20 stop'
      @pid_file = '/var/run/apache90.pid'

      @server_alias = 'my home server'
      @hostname = '192.168.2.2'

      super
    end
  end

describe Ragios::Monitors::Process do 

  before(:each) do
   @ma = MonitorApache.new
   @mau = MonitorApacheUnknown.new
  end


 it "should PASS the test when apache is running" do 
     @ma.test_command.should == TRUE
 end 

 it "should FAIL  because the process doesnt exist" do
     @mau.test_command.should == FALSE
 end

end



