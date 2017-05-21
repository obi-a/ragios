# Loads a generic monitor from the database using the monitor's id
module Ragios
  class MonitorLoader

    attr_reader :generic_monitor, :monitor_id, :monitor
    attr_reader :model

    def initialize(options = {})
      @monitor_id = options[:_id]
      @monitor = model.find(@monitor_id)
      monitor.merge(options)
      @generic_monitor = Generic_monitor(monitor)
    end

  private

    def model
      @model ||= Ragios::Database::Model.new(Ragios::CouchdbAdmin.get_database)
    end
  end
end
