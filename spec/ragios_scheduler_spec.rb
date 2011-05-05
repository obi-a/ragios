require 'spec_base.rb'

class Monitor1 < Ragios::Monitors::System
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test 1"
      @describe_test_result = "sample test 1"
      @test_result = "sample result"
     super
   end 

   def test_command
      TRUE 
   end
  
   def notify
     gmail_notify
  end

  def fixed
     gmail_resolved
  end  
end


class Monitor2 < Ragios::Monitors::System
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test 2"
      @describe_test_result = "sample test 2"
      @test_result = "sample result"
     super
   end 

   def test_command
      TRUE 
   end
  
   def notify
     gmail_notify
  end

  def fixed
     gmail_resolved
  end  
end

class Monitor3 < Ragios::Monitors::System
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test 3"
      @describe_test_result = "sample test 3"
      @test_result = "sample result"
     super
   end 

   def test_command
      FALSE 
   end
  
   def notify
     gmail_notify
  end

  def fixed
     gmail_resolved
  end  
end

class BadCodeMonitor < Ragios::Monitors::System
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test 3"
      @describe_test_result = "sample test 3"
      @test_result = "sample result"
     super
   end 

   def error_handler
       puts 'handled the error situation'
   end

   def test_command
      raise "something is wrong"
   end
end



describe Ragios::Schedulers::RagiosScheduler do

    before(:each) do
     @ragios = Ragios::Schedulers::RagiosScheduler.new [Monitor1.new, Monitor2.new,Monitor3.new]
    end 

    it "should initalize all monitors and run their test command" do 
      @ragios.init
    end

    it "should throw an exception during init() when  a monitor's test_command() generates an error" do 
       badlycoded = Ragios::Schedulers::RagiosScheduler.new [ BadCodeMonitor.new]
       #scheduler catches exceptions generated the monitor's test_command() during init() 
       #and raises the exception again after passing it to a handler if one is implemented  
       lambda {badlycoded.init}.should raise_error(RuntimeError,"something is wrong")     
    end
  
   it "should throw an exception: will not start monitoring because a monitor's test_command() generates an error" do 
      monitoring_bad_monitor = [BadCodeMonitor.new]
      lambda {Ragios::System.start monitoring_bad_monitor}.should raise_error(RuntimeError,"something is wrong")  
   end

    
    it "should schedule all monitors to run their tests at their specified time interval" do 
       @ragios.start
    end

    it "should display stats on active each monitor" do
      monitors = @ragios.get_monitors   
       
      monitors.each do |monitor|  
         puts monitor.test_description 
         puts monitor.creation_date
         puts monitor.time_of_last_test
      end
    end
   
    it "should scheduler a status report to be sent out at the specified interval" do
       @ragios.update_status({:every => '60m',
			:contact => 'admin@mail.com',
			:via => 'gmail'}) 
    end
    
   it "should display the status report" do
     lambda {@ragios.status_report}.should raise_error(RuntimeError, "Error Generating Status Report: At least one Monitor has total_number_of_tests_performed  = 0")
     
   end
end
