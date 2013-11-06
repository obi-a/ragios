require 'spec_base.rb'

describe Ragios::Scheduler do

  it "should schedule a controller to perform" do
    args = {time_interval: '2m', object: 'object', tag: 'test'}
    controller = double('controller')
    controller.stub(:perform)
    scheduler = Ragios::Scheduler.new(controller)
    job = scheduler.schedule(args)
    job.params[:tags].should == ['test']
    job.t.should == '2m'
    job.unschedule
  end
 
  it "should unschedule a job" 
  
  it "should find a job by tag"
  
  it "should return all jobs"
end
