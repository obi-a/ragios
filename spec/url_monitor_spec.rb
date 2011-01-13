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

end

describe Ragios::Monitors::URL do

  before(:each) do
   @um = URLMonitor.new
   @fum = FailedURLMonitor.new
   @hsm = HttpsMonitor.new
  end

 it "should send a http request pass" do
    @um.test_command.should == TRUE
 end

 it "should send a http request and fail" do 
    @fum.test_command.should ==  FALSE
 end 

 it "should send a request via https and pass" do 
   @hsm.test_command.should == TRUE
end

end
