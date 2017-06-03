module Ragios
  class RecuringJobScheduler
    include Celluloid

    attr_reader :scheduler, :work_pusher

    def initialize(work_pusher)
      @work_pusher = Ragios::WorkPusher.new
      @scheduler = Rufus::Scheduler.new
    end

    def perform(options_array)
      options = JSON.parse(options_array.first, symbolize_names: true)
      if options[:_first_run]
        run_now_and_schedule(options)
      elsif options[:_unschedule]
        unschedule(options)
      else
        schedule_and_run_later(options)
      end
    end

    #TODO: DRY up later
    def run_now_and_schedule(options_array)
      options =  JSON.parse(options_array.first, symbolize_names: true)
      @scheduler.interval options[:interval], :first => :now,  :tags => options[:monitor_id] do
        trigger_work(options)
      end
    end

    def schedule_and_run_later(options_array)
      options =  JSON.parse(options_array.first, symbolize_names: true)
      @scheduler.interval options[:interval],  :tags => options[:monitor_id] do
        trigger_work(options)
      end
    end

    def trigger_work(options)
      @work_pusher.push(options[:monitor_id])
      publisher.async.log_event!(
        monitor_id: options[:monitor_id],
        event: {"monitor status" => "triggered"},
        state: "triggered",
        time: Time.now.utc,
        type: "event",
        event_type: "monitor.triggered"
      )
      puts "#{options[:monitor_id]} triggered work"
    end

    def unschedule(job_id)
    end

    def terminate
      @work_pusher.terminate
      @socket.close
      super
    end

  private
    def publisher
      Ragios::EventPublisher.new
    end
  end
end
