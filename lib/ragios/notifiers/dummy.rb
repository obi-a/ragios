module Ragios
  module Notifiers
    class Sample
      def init(monitor); end
      def failed(test_result); end
      def resolved(test_result); end
    end
  end
end
