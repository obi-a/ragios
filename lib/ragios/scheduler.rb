module Ragios 
  class Scheduler
    def initialize(ctr)
      @scheduler = Rufus::Scheduler.start_new 
      @controller = ctr
    end
    
    def stop(tag)
      jobs = @scheduler.find_by_tag(tag)
      jobs.each do |job| 
        job.unschedule
      end 
    end
    
    def schedule(args)
      @scheduler.every args[:time_interval], :tags => args[:tag] do          
        controller.perform(args[:object])
      end  
    end
    
    def find(tag)
      @scheduler.find_by_tag(tag)
    end
    
    def all
      @scheduler.jobs
    end
    
    def controller
      @controller
    end
  end
end 
