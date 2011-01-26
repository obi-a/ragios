require 'spec_base.rb'

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

end

describe Ragios::Monitors::HTTP do

  before(:each) do
   @hm = HTTPMonitor.new
   @fhm = FailedHTTPMonitor.new
  end

 it "should establish a http connection with google.com" do
    @hm.test_command.should == TRUE
 end

 it "should fail to establish a http connection" do 
    @fhm.test_command.should ==  FALSE
 end 
end
