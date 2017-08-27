module Ragios
  module Events
    class Worker
      include Celluloid

      def perform(options)
        @event =  JSON.parse(options, symbolize_names: true)
        log_event
      end

    private

      def log_event
        model.save(unique_id, @event)
        Ragios.log_event(self, "logged", @event)
      end

      def unique_id
        SecureRandom.uuid
      end

      def model
        @model ||= Ragios::Database::Model.new
      end
    end
  end
end
