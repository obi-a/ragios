module Ragios
  module Notifier
    class Dummy
      def initialize(monitor); end
      def failed(monitor); end
      def resolved(monitor); end
    end
 end
end

