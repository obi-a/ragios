module Ragios
  class Scheduler
    def initialize(ctr)
      @scheduler = Rufus::Scheduler.new
      @controller = ctr
    end
    def unschedule(tag)
      jobs = find(tag)
      jobs.each do |job|
        job.unschedule
      end
    end
    def schedule(args)
      @scheduler.interval args[:time_interval], :first => :now,  :tags => args[:tags] do
        controller.perform(args[:object])
      end
    end
    def find(tag)
      @scheduler.jobs(tag: tag)
    end
    def all
      @scheduler.jobs
    end
    def controller
      @controller
    end
  end
end
