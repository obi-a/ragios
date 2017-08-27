module Ragios
  module Events
    class Publisher < ZMQ::Publisher

      def initialize
        super(
          link: Ragios::SERVERS[:events_subscriber],
          action: :connect_link
        )
      end
    end
  end
end
