# Loads a generic monitor from the database using the monitor's id
module Ragios
  module Monitors
    class Loader

      attr_reader :generic_monitor, :monitor_id, :monitor
      attr_reader :model

      def initialize(monitor_id)
        @monitor_id = monitor_id
        @monitor = model.find(@monitor_id)
        current_state  =  model.get_monitor_state(@monitor_id)
        puts "current_state #{current_state.inspect}"
        @generic_monitor = GenericMonitor.new(@monitor)
        @generic_monitor.state = current_state[:state]
      end

    private

      def model
        @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
      end
    end
  end
end
