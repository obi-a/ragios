require 'spec_base.rb'

describe Ragios::Monitors::GenericMonitor do
  describe "#create_plugin" do
    context "when plugin is included in options" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin implements init(options)" do
            it "creates the plugin" do
              module Ragios
                module Plugin
                  class GoodPlugin
                    attr_reader :test_result
                    def init(options); end
                    def test_command?; end
                  end
                end
              end
              options = {plugin: "good_plugin"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect(generic_monitor.create_plugin).to be_a(Ragios::Plugin::GoodPlugin)
              expect(generic_monitor.plugin).to be_a(Ragios::Plugin::GoodPlugin)
            end
          end
        end
      end
    end
    context "when plugin does not implement test_command?" do
      context "when plugin defines test_result" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestCommandNotImplemented exception, plugin not is created" do
              module Ragios
                module Plugin
                  class PluginWithNoTestCmd
                    attr_reader :test_result
                    def init(options); end
                  end
                end
              end

              options = {plugin: "plugin_with_no_test_cmd"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestCommandNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not define test_result" do
      context "when plugin implements test_command?" do
        context "when plugin is included in options" do
          context "when plugin implements init(options)" do
            it "raises a PluginTestResultNotDefined exception, plugin is not created" do
              module Ragios
                module Plugin
                  class PluginWithNoTestResult
                    def init(options); end
                    def test_command?; end
                  end
                end
              end

              options = {plugin: "plugin_with_no_test_result"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginTestResultNotDefined)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when plugin does not implement init(options) metho" do
      context "when plugin defines test_result" do
        context "when plugin implements test_command" do
          context "when plugin is included in options" do
            it "raises a PluginInitNotImplemented exception, plugin is not created" do
              module Ragios
                module Plugin
                  class PluginWithNoInit
                    attr_reader :test_result
                    def test_command?; end
                  end
                end
              end
              options = {plugin: "plugin_with_no_init"}
              generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
              expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginInitNotImplemented)
              expect(generic_monitor.plugin).to be_nil
            end
          end
        end
      end
    end
    context "when there is no plugin in options" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
    context "when plugin key in options is not a symbol" do
      it "raises a PluginNotFound exception, plugin is not created" do
        options = {"plugin" => "plugin" }
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_plugin}.to raise_error(Ragios::PluginNotFound)
        expect(generic_monitor.plugin).to be_nil
      end
    end
  end
  describe "#create_notifiers" do
    context "when notifiers are not included in options" do
      it "raises a NotifierNotFound exception" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
    context "when notifiers list is empty in options" do
      it "raises a NotifierNotFound exception" do
        options = {via: []}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect{generic_monitor.create_notifiers}.to raise_error(Ragios::NotifierNotFound)
        expect(generic_monitor.notifiers).to be_nil
      end
    end
  end
end
