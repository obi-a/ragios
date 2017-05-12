module Ragios
  class Job
    include Celluloid

    attr_reader :monitor_id, :interval, :timer

    def initialize(options)
      @monitor_id = options[:monitor_id]
      @interval = options[:interval]
    end

    def start
      @timer = every(interval) do
        trigger_work
      end
    end

    def trigger_work
      puts "triggered work"
    end
  end
end
