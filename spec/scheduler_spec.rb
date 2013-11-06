require 'spec_base.rb'

describe Ragios::Scheduler do

  it "should schedule a controller to perform" do
    time_interval = '2m'
    tag = 'test'
    args = {:time_interval => time_interval, :object => 'object', :tag => tag}
    controller = double('controller')
    controller.stub(:perform)
    scheduler = Ragios::Scheduler.new(controller)
    job = scheduler.schedule(args)
    job.params[:tags].should == [tag]
    job.t.should == time_interval
    job.unschedule
  end
 
  it "should unschedule a job" 
  
  it "should find a job by tag"
  
  it "should return all jobs"
end
