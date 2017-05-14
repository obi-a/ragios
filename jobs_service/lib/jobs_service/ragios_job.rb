module Ragios
  class RagiosJob
    include Celluloid

    attr_reader :monitor_id, :interval, :timer

    def init(options_array)
      options =  JSON.parse(options_array.first, symbolize_names: true)
      @monitor_id = options[:monitor_id]
      @interval = options[:interval]
      start
    end

    def start
      @timer = every(interval) do
        trigger_work
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
