require 'spec_base.rb'

describe Ragios::Scheduler do
  before(:each) do
    @time_interval = '2m'
    @tag = 'test'
    @args = {:time_interval => @time_interval, :object => 'object', :tag => @tag}   
  end

  it "should schedule a job" do
    scheduler = Ragios::Scheduler.new('an object')
    job = scheduler.schedule(@args)
    job.params[:tags].should == [@tag]
    job.t.should == @time_interval
    job.unschedule
  end
 
  it "should unschedule a job" do
    scheduler = Ragios::Scheduler.new('an object')
    scheduler.schedule(@args)  
    jobs = scheduler.find(@tag) 
    jobs.first.params[:tags].should == [@tag]
    jobs.first.t.should == @time_interval
    scheduler.stop(@tag)
    jobs = scheduler.find(@tag) 
    jobs.should == []
  end
end
