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



describe Ragios::System do

   before(:each) do
     @monitoring = [Monitor1.new, Monitor2.new, Monitor3.new]
  end 

 it "should initialize all monitors and activate the scheduler" do 
     @monitors = Ragios::System.start @monitoring 
     @monitors.each do |monitor|  
         monitor.total_num_tests.should == 1
         puts monitor.test_description 
         puts monitor.creation_date
         puts monitor.time_of_last_test
     end
 end

 it "should setup status reports" do
   Ragios::System.update_status({:every => '40s',
			:contact => 'obi.akubue@mail.com',
			:via => 'gmail'})  
 end   
end






