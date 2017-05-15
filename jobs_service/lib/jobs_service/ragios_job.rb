module Ragios
  class RagiosJob
    include Celluloid

    attr_reader :monitor_id, :interval, :scheduler

    def initialize(options_array)
      options =  JSON.parse(options_array.first, symbolize_names: true)
      @monitor_id = options[:monitor_id]
      @interval = options[:interval]
    end

    def start
      @scheduler.interval args[:time_interval], :first => :now,  :tags => args[:tags] do
        @work_queue.push args[:object]
      end
    end

    def trigger_work
      puts "#{@monitor_id} triggered work"
    end

    def exception_handler
      $stderr.puts '-' * 80
      $stderr.puts "ERROR: #{monitor_id} at interval #{interval} seconds"
      $stderr.puts '-' * 80
      super
    end
  end
end
