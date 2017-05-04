module Ragios
  class MonitorsManager

    attr_reader :model
    def initialize(options = {})
    end

    def add(options)
      event_time = time
      monitor_options = options.merge({created_at_: event_time, status_: 'active', type: "monitor"})

      #add_to_scheduler(this_generic_monitor)
      #add monitor's job to scheduler
      model.save(unique_id, monitor_options)
      #log_event(
      #  monitor_id: this_generic_monitor.id,
      #  event: {"monitor status" => "created"},
      #  state: "create",
      #  time: event_time,
      #  type: "event",
      #  event_type: "monitor.create"
      # )
      #log_monitor_start(this_generic_monitor.id, this_generic_monitor.options)
      #return this_generic_monitor.options
    end

    def model
      @model ||= Ragios::Database::Model.new(Ragios::CouchdbAdmin.get_database)
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