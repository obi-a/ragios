module Ragios
  module ZMQ
    class Pusher < Base

      def push(monitor_id)
        write(monitor_id)
        puts "#{Time.now} push work for monitor_id: #{monitor_id} to worker"
      end

    protected

      def write(message)
        @socket << message
        nil
      end
    end
  end
end
