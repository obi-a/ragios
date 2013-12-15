module Ragios
  module Plugin

    class MockPlugin
      attr_accessor :test_result

      def init(options)
      end

      def test_command
        @test_result = {"This test" => "does nothing"}
        return true
      end
    end

  end
end
