module Ragios
  module Notifier
    class MockNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed
        puts "#{@monitor.options[:monitor]} FAILED"
        puts "#{@monitor.test_result.inspect}"
      end
      def resolved
        puts "#{@monitor.options[:monitor]} RESOLVED"
        puts "#{@monitor.test_result.inspect}"
      end
    end
 end
end
