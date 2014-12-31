#Controller for events
module Ragios
  class Events
    #see contracts: https://github.com/egonSchiele/contracts.ruby
    include Contracts
    #types
    Event = Hash
    Event_id = String

    def self.model
      @model ||= Ragios::Database::Model.new(Ragios::CouchdbAdmin.get_database)
    end

    def self.reset
      @model = nil
    end

    def self.get(event_id)
      try_event(event_id) do
        event = model.find(event_id)
      end
    end

    def self.delete(event_id)
      try_event(event_id) do
        model.delete(event_id)
      end
    end

    def self.all(options = {})
      model.get_all_events(options)
    end

  private
    def self.try_event(event_id)
      yield
    rescue Leanback::CouchdbException => e
      handle_error(event_id, e)
    end

    def self.handle_error(event_id, e)
      if e.response[:error] == "not_found"
        raise Ragios::EventNotFound.new(error: "No event found"), "No event found with id = #{event_id}"
      else
        raise e
      end
    end

    def self.get_valid_event(event_id)
      event = model.find(event_id)
      if event[:type] != "event"
        raise Ragios::EventNotFound.new(error: "No event found"), "No event found with id = #{event_id}"
      else
        return event
      end
    end
  end
end
