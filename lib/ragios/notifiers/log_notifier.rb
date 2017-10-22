module Ragios
  module Notifiers
    class LogNotifier

       attr_reader :level

      def initialize(log_level = :info)
        @level = log_level
      end

      def init(monitor)
        @monitor = monitor
      end

      def failed(test_result)
        logger.send(level, "#{@monitor[:monitor]} FAILED")
        logger.send(level, "#{test_result.inspect}")
      end

      def resolved(test_result)
        logger.send(level, "#{@monitor[:monitor]} RESOLVED")
        logger.send(level, "#{test_result.inspect}")
      end

      def logger
        Ragios.logger
      end
    end
  end
end
