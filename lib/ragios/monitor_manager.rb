module Ragios
  class MonitorManager

    attr_reader :monitor

    def initialize(monitor)
      #add monitor to database
    end

    def schedulable?
      # checks if monitor can be scheduled
      # runs the necessary validations
    end

    def schedule
      # spawns a new thread of the job to start running on its schedule
    end

    def self.startup_monitors
      #runs during startup
      #load monitors from database
      #schedule them to run
    end
  end
end
