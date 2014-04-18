module Ragios
  module Notifier
    class MockNotifier
      def initialize(monitor)
        @monitor = monitor
      end
      def failed(monitor)
        @monitor = monitor
        puts "#{@monitor[:monitor]} FAILED"
        puts "#{@monitor[:test_result_].inspect}"
      end
      def resolved(monitor)
        @monitor = monitor
        puts "#{@monitor[:monitor]} RESOLVED"
        puts "#{@monitor[:test_result_].inspect}"
      end
    end
 end
end
