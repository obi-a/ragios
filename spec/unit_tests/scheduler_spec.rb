require 'spec_base.rb'

describe Ragios::Scheduler do
  before(:each) do
    @time_interval = '2m'
    @tag = 'test'
    @args = {:time_interval => @time_interval, :object => 'object', :tags => @tag}
  end

  it "should schedule a job" do
    scheduler = Ragios::Scheduler.new('an object')
    scheduler.schedule(@args)
    jobs = scheduler.find(@tag)
    jobs.first.tags.should == [@tag]
    jobs.first.original.should == @time_interval
    scheduler.stop(@tag)
  end

  it "should unschedule a job" do
    scheduler = Ragios::Scheduler.new('an object')
    scheduler.schedule(@args)
    jobs = scheduler.find(@tag)
    jobs.first.tags.should == [@tag]
    jobs.first.original.should == @time_interval
    scheduler.stop(@tag)
    jobs = scheduler.find(@tag)
    jobs.should == []
  end
end
