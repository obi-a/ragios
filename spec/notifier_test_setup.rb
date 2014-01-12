module Ragios
  module Plugin
    class PassingPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        @test_result = {result:'PASSED'}
        return true
      end
    end
  end
end

module Ragios
  module Plugin
    class FailingPlugin
      attr_accessor :test_result
      def init(options)
      end
      def test_command?
        @test_result = {result:'FAILED'}
        return false
      end
    end
  end
end

module Ragios
  module NotifierTest
    def self.failed_resolved(monitor, notifier)
      controller = Ragios::Controller
      controller.scheduler(Ragios::Scheduler.new(Ragios::Controller))
      controller.model(Ragios::Model::CouchdbMonitorModel)
      controller.logger(Ragios::CouchdbLogger.new)
      failing_monitor = {monitor: monitor,
        every: "5m",
        via: notifier,
        contact: ENV['RAGIOS_CONTACT'],
        plugin: "failing_plugin" }

      #test should fail and send a FAILED notification message
      monitor_id = controller.add([failing_monitor]).first.id

      #controller.update automatically restarts and tests monitor
      #test should pass this time and send a PASSED notification message
      controller.update(monitor_id, plugin: "passing_plugin")
      controller.delete(monitor_id)
      sleep 1 #delay for background processing to complete
    end
  end
end
