module Ragios
  class MonitorManager

    attr_reader :monitor

    def initialize(options)
      #add monitor to database
    end

    def schedulable?
      # checks if monitor can be scheduled
      # runs the necessary validations
    end

    def schedule
      # spawns a new thread of the job to start running on its schedule
      Ragios::Job.supervise_as(monitor_id, options)
    end

    def self.startup_monitors
      #runs during startup
      #load monitors from database
      #schedule them to run
    end

    private

    def time
      Time.now.utc
    end

    def unique_id
      SecureRandom.uuid
    end
  end
end
