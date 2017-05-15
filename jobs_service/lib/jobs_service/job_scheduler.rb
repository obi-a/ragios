module Ragios
  class JobScheduler
    include Celluloid

    attr_reader :scheduler

    def initialize
      @scheduler = Rufus::Scheduler.new
    end

    def schedule(options_array)
      options =  JSON.parse(options_array.first, symbolize_names: true)
      @scheduler.interval options[:interval], :first => :now,  :tags => options[:monitor_id] do
        trigger_work(options)
      end
    end

    def trigger_work(options)
      puts "#{options[:monitor_id]} triggered work"
    end
  end
end
