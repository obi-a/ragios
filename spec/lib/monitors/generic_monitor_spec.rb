require 'spec_base.rb'

describe Ragios::Monitors::GenericMonitor do
  describe "#validate_plugin_in_options" do
    context "when options has no plugin" do
      it "raises a No plugin found exception" do
        options = {}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect(generic_monitor.options).to eq(options)
        expect{generic_monitor.validate_plugin_in_options}.to raise_error(Ragios::PluginNotFound)
      end
    end

    context "when options has a plugin" do
      it "Returns true" do
        options = {plugin: :plugin}
        generic_monitor = Ragios::Monitors::GenericMonitor.new(options, true)
        expect(generic_monitor.options).to eq(options)
        expect(generic_monitor.validate_plugin_in_options).to eq(true)
      end
    end
  end
end
