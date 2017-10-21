module Ragios
  module Plugin

    class MockPlugin
      attr_reader :test_result

      def init(monitor); end

      def test_command?
        @test_result = {"This test" => "does nothing"}
        return ((rand(1..10) % 2 == 0) ? true : false)
      end
    end

  end
end
