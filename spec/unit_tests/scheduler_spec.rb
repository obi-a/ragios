require 'spec_base.rb'

@@performed = false

class MockController
  def perform(object)
    @@performed = true
  end
end

describe Ragios::Scheduler do
  before(:each) do
    @time_interval = '2h'
    @tag = 'test'
    @args = {:time_interval => @time_interval, :object => 'object', :tags => @tag}
  end

  it "should schedule a job, trigger immediately and at intervals" do
    scheduler = Ragios::Scheduler.new(MockController.new)
    scheduler.schedule(@args)
    sleep 11
    #first test is performed by the worker after 10s immediately
    unless RUBY_PLATFORM == "java"
      #jruby using java threads will yield a different result for the
      #class variable @@performed
      #jobs still trigger immediately for jruby so its not necessary to make the below assertion
      @@performed.should == true
    end
    #verify that job was scheduled
    jobs = scheduler.find(@tag)
    jobs.first.tags.should == [@tag]
    jobs.first.original.should == @time_interval
    scheduler.unschedule(@tag)
  end

  it "should unschedule a job" do
    scheduler = Ragios::Scheduler.new(MockController.new)
    scheduler.schedule(@args)
    jobs = scheduler.find(@tag)
    jobs.first.tags.should == [@tag]
    jobs.first.original.should == @time_interval
    scheduler.unschedule(@tag)
    jobs = scheduler.find(@tag)
    jobs.should == []
  end
end
