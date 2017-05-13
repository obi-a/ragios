require 'celluloid/debug'
require "celluloid/current"
require "json"

module Ragios
  class Job
    include Celluloid

    attr_reader :monitor_id, :interval, :timer

    def initialize(options_str)
      options =  JSON.parse(options_str, symbolize_names: true)
      @monitor_id = options[:monitor_id]
      @interval = options[:interval]
    end

    def start
      @timer = every(interval) do
        trigger_work
      end
    end

    def trigger_work
      puts "#{@monitor_id} triggered work"
    rescue => e
      send_stderr(e)
      raise e
    end

    def send_stderr(exception)
      $stderr.puts '-' * 80
      $stderr.puts "ERROR: #{monitor_id} at interval #{interval} seconds"
      $stderr.puts exception.message
      $stderr.puts '-' * 80
    end
  end
end
