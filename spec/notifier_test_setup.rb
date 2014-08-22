require File.expand_path(File.join(File.dirname(__FILE__), '..', 'initializers/init_notifiers.rb'))

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

database_admin = {
  username: ENV['COUCHDB_ADMIN_USERNAME'],
  password: ENV['COUCHDB_ADMIN_PASSWORD'],
  database: "ragios_test_notifiers_database",
  address: 'http://localhost',
  port: '5984'
}
Ragios::CouchdbAdmin.config(database_admin)
Ragios::CouchdbAdmin.setup_database

module Ragios
  module NotifierTest
    def self.failed_resolved(monitor, notifier)
      controller = Ragios::Controller
      failing_monitor = {
        monitor: monitor,
        every: "5m",
        via: notifier,
        contact: ENV['RAGIOS_CONTACT'],
        plugin: "failing_plugin"
      }

      #test should fail and send a FAILED notification message
      monitor_id = controller.add(failing_monitor)[:_id]
      sleep 1
      #controller.update automatically restarts and tests monitor
      #test should pass this time and send a PASSED notification message
      controller.update(monitor_id, plugin: "passing_plugin")
      sleep 1 #delay for background processing to complete
      controller.delete(monitor_id)
    end
  end
end
