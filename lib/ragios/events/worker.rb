module Ragios
  module Events
    class Worker
      include Celluloid

      def perform(options)
        puts options.inspect
        @event =  JSON.parse(options, symbolize_names: true)
        log_event
      end

    private

      def log_event
        model.save(unique_id, @event)
      end

      def unique_id
        SecureRandom.uuid
      end

      def model
        @model ||= Ragios::Database::Model.new(Ragios::Database::Admin.get_database)
      end
    end
  end
end
