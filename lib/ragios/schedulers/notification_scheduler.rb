
module Ragios 
module Schedulers


class NotificationScheduler
  attr_accessor :scheduler
  attr_reader :job
  attr_accessor :thread

  def initialize job   
      @job =  job
      
  end 

  def unschedule
     #puts @thread.inspect
     @thread.unschedule 
  end

  def start
     @scheduler = Rufus::Scheduler.start_new
     # setup scheduler to send notifcations at every  notification interval
    @thread = @scheduler.every  @job.notification_interval, :tags => @job.id do |this_job|
      if @job.test_command
        #test passed, the condition is no longer true 
        #unschedule this job
        this_job.unschedule 
      else 
        @job.notify
      end
     end
  end

end

 end
end



