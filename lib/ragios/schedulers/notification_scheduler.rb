
module Ragios 
module Schedulers


class NotificationScheduler
  attr_accessor :scheduler
  attr_reader :job

  def initialize job   
      @job =  job
      
  end 

  def self.unschedule(id)
   jobs = @scheduler.find_by_tag(id)
   if jobs != nil
    jobs.each do |job|
        job.unschedule 
    end
   end
  end

  def start
     @scheduler = Rufus::Scheduler.start_new
     # setup scheduler to send notifcations at every  notification interval
     @scheduler.every  @job.notification_interval, :tags => @job.id  do |this_job|
      if @job.test_command
        #test passed, the condition is no longer true 
        #unschedule this job
        this_job.unschedule 
        #@job.fixed
      else 
        @job.notify
      end
     end
  end

end

 end
end



