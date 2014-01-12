module Ragios
  module Plugin

    class MockPlugin
      attr_reader :test_result

      def init(monitor)
      end

      def test_command?
        @test_result = {"This test" => "does nothing"}
        return true
      end
    end

  end
end
