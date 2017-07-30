module Ragios
  module Notifier
    class MockNotifier
      def init(monitor)
        @monitor = monitor
      end
      def failed(test_result)
        puts "#{@monitor[:monitor]} FAILED"
        puts "#{test_result.inspect}"
      end
      def resolved(test_result)
        puts "#{@monitor[:monitor]} RESOLVED"
        puts "#{test_result.inspect}"
      end
    end
 end
end
