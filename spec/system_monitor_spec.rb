require 'spec_base.rb'

class SystemMonitor < Ragios::Monitors::System
   def initialize
      @time_interval = '10m'
      @notification_interval = '6h'
      @contact = "obi@mail.com"
      @test_description = "sample test"
      @describe_test_result = "sample test"
      @test_result = "sample result"
      super
   end
end


describe Ragios::Monitors::System do
  
  before(:each) do
    @sm = SystemMonitor.new
  end

context "notifications" do

 it "should send gmail resolved message" do
   @sm.gmail_resolved
 end
   
   
 it "should send email resolved message" do
   @sm.email_resolved
 end


 it "should send tweet resolved message" do 
  @sm.tweet_resolved
 end

 it "should send gmail notify message" do 
   @sm.gmail_notify
 end
 
 it "should send tweet notify message" do
   @sm.tweet_notify
 end

 it "should send email notify message" do
   @sm.email_notify
 end

 it "should send tweet error message" do
  @sm.tweet_error
 end
 
end

end
