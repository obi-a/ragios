
module Ragios 
module Schedulers


class NotificationScheduler

  attr_reader :job

  def initialize job   
      @job =  job
      
  end 

  def start
     scheduler = Rufus::Scheduler.start_new
     # setup scheduler to send notifcations at every  notification interval
     scheduler.every  @job.notification_interval do |this_job|
      if @job.test_command
        #test passed, the condition is no longer true 
        #unschedule this job
        this_job.unschedule 
        @job.fixed
      else 
         @job.notify
        
      end
     end
  end

end

 end
end



