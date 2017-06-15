# Loads a generic monitor from the database using the monitor's id
module Ragios
  module Monitors
    class Loader

      attr_reader :generic_monitor, :monitor_id, :monitor
      attr_reader :model

      def initialize(options)
        @monitor_id = options[:_id]
        @monitor = model.find(@monitor_id)
        monitor.merge(options)
        #set initial state
        @generic_monitor = GenericMonitor.new(monitor)
      end

    private

      def model
        @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
      end
    end
  end
end
