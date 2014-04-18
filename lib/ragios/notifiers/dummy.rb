module Ragios
  module Notifier
    class Dummy
      def initialize(monitor); end
      def failed(test_result); end
      def resolved(test_result); end
    end
 end
end

