module Ragios
  module ZMQ
    class Pusher < Base

      def push(message)
        @socket << message
        Ragios.logger.info "#{self.class.name } pushed message: #{message}"
      end
    end
  end
end
