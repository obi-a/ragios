module Ragios
  class Worker
    include Celluloid

    attr_reader :generic_monitor, :monitor_id

    def initialize(monitor_id)
      @monitor_id = monitor_id
      @generic_monitor =  Ragios::MonitorLoader.new(monitor_id)
    end

    def perform
      @generic_monitor.test_command?
      publish_event
    rescue Exception => e
      log_error(e)
      raise e
    end

    def publish_event
    end

    def log_error
      #do something
      publish_event
    end
  end
end
