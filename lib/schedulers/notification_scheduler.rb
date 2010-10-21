
class NotificationScheduler

  attr_reader :job

  def initialize job   
      @job =  job
      @job.notify  
  end 

  def start
     # setup scheduler to send notifcations at every  notification interval
     scheduler.every @job.notification_interval do |this_job|
     begin 
      if @job.test_command
        #test passed, the condition is no longer true
        #unschedule this scheduler
        this_job.unschedule 
      else 
         @job.notify
      end
     end
  end

end


