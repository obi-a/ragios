require 'spec_base.rb'

describe Ragios::Monitors::Manager do
  before(:each) do
    @manager = Ragios::Monitors::Manager.new
  end

  describe "#stop" do
    it "stops the monitor with id" do
      monitor_id = SecureRandom.uuid
      expect(Ragios::Monitors::GenericMonitor).to receive(:stop).with(monitor_id)
      expect(@manager).to receive(:log_monitor).with(:stop, monitor_id)
      stopped = @manager.stop(monitor_id)
      expect(stopped).to be_truthy
    end
  end

  describe "#get" do
    it "returns the monitor options" do
      monitor_id = SecureRandom.uuid
      expect(Ragios::Monitors::GenericMonitor).to receive(:find).with(monitor_id).and_return(
        Ragios::Monitors::GenericMonitor.new({_id: monitor_id}, skip_extensions_creation = true)
      )
      retrieved = @manager.get(monitor_id)
      expect(retrieved).to eq(_id: monitor_id)
    end
  end

  describe "#add" do
    it "creates and adds the new monitor using options" do
      monitor_id = SecureRandom.uuid
      options = {monitor: "testing add action"}
      options_with_id = options.merge(_id: monitor_id)
      expect(Ragios::Monitors::GenericMonitor).to receive(:create).with(options).and_return(
        Ragios::Monitors::GenericMonitor.new(options_with_id, skip_extensions_creation = true)
      )
      expect(@manager).to receive(:log_monitor).with(:create, monitor_id)
      expect(@manager).to receive(:log_monitor).with(:start, monitor_id)

      added = @manager.add(options)
      expect(added).to eq(options_with_id)
    end
  end

  describe "#delete" do
    it "deletes the monitor with id" do
      monitor_id = SecureRandom.uuid
      expect(Ragios::Monitors::GenericMonitor).to receive(:delete).with(monitor_id)
      expect(@manager).to receive(:log_monitor).with(:delete, monitor_id)
      deleted = @manager.delete(monitor_id)
      expect(deleted).to be_truthy
    end
  end

  describe "#update" do
    it "updates the monitor with provided options" do
      monitor_id = SecureRandom.uuid
      options = {monitor: "updating monitor"}
      expect(Ragios::Monitors::GenericMonitor).to receive(:update).with(monitor_id, options)
      expect(@manager).to receive(:log_monitor).with(:update, monitor_id, update: options)
      updated = @manager.update(monitor_id, options)
      expect(updated).to be_truthy
    end
  end

  describe "#start" do
    it "starts the monitor" do
      monitor_id = SecureRandom.uuid
      expect(Ragios::Monitors::GenericMonitor).to receive(:start).with(monitor_id)
      expect(@manager).to receive(:log_monitor).with(:start, monitor_id)
      started = @manager.start(monitor_id)
      expect(started).to be_truthy
    end
  end

  describe "#test_now" do
    it "tests the monitor" do
      monitor_id = SecureRandom.uuid
      expect(Ragios::Monitors::GenericMonitor).to receive(:trigger).with(monitor_id)
      tested = @manager.test_now(monitor_id)
      expect(tested).to be_truthy
    end
  end
  describe "#get_all" do
    it "returns all monitors" do
      results = []
      expect(@manager.model).to receive(:all_monitors).with({}).and_return(results)
      monitors = @manager.get_all

      expect(monitors).to eq(results)
    end
  end

  describe "#get_events_by_state" do
    it "returns events by state" do
      results = []
      expect(@manager.model).to receive(:get_monitor_events_by_state).with("monitor_id", "state", {}).and_return(results)
      monitors = @manager.get_events_by_state("monitor_id", "state", {})

      expect(monitors).to eq(results)
    end
  end

  describe "#get_events_by_type" do
    it "returns events by type" do
      results = []
      expect(@manager.model).to receive(:get_monitor_events_by_type).with("monitor_id", "event_type", {}).and_return(results)
      monitors = @manager.get_events_by_type("monitor_id", "event_type", {})

      expect(monitors).to eq(results)
    end
  end

  describe "#get_events" do
    it "returns events by monitor_id & options" do
      results = []
      expect(@manager.model).to receive(:get_monitor_events).with("monitor_id", {}).and_return(results)
      monitors = @manager.get_events("monitor_id", {})

      expect(monitors).to eq(results)
    end
  end

  describe "#where" do
    it "returns monitors by options" do
      results = []
      expect(@manager.model).to receive(:monitors_where).with({}).and_return(results)
      monitors = @manager.where({})

      expect(monitors).to eq(results)
    end
  end

  describe "#get_current_state" do
    it "resturns current state for provided monitor" do
      result = {}
      expect(@manager.model).to receive(:get_monitor_state).with("monitor_id").and_return(result)
      monitors = @manager.get_current_state("monitor_id")

      expect(monitors).to eq(result)
    end
  end

  describe "#log_monitor" do
    before(:each) do
      Celluloid.shutdown; Celluloid.boot
    end

    it "logs monitor start event publishing to events subscriber" do
      subcriber = Ragios::Events::Subscriber.new
      future = subcriber.future.receive
      @manager.log_monitor(:start, "monitor_id")
      received = JSON.parse(future.value, symbolize_names: true)
      expect(received).to include(
        monitor_id: "monitor_id",
        event: {:"monitor status" => "started"},
        state: "started",
        type: "event",
        event_type: "monitor.start"
      )
    end

    it "logs monitor create event publishing to events subscriber" do
      subcriber = Ragios::Events::Subscriber.new
      future = subcriber.future.receive
      @manager.log_monitor(:create, "monitor_id")
      received = JSON.parse(future.value, symbolize_names: true)
      expect(received).to include(
        monitor_id: "monitor_id",
        event: {:"monitor status" => "created"},
        state: "create",
        type: "event",
        event_type: "monitor.create"
      )
    end

    it "logs monitor stop event publishing to events subscriber" do
      subcriber = Ragios::Events::Subscriber.new
      future = subcriber.future.receive
      @manager.log_monitor(:stop, "monitor_id")
      received = JSON.parse(future.value, symbolize_names: true)
      expect(received).to include(
        monitor_id: "monitor_id",
        event: {:"monitor status" => "stopped"},
        state: "stopped",
        type: "event",
        event_type: "monitor.stop"
      )
    end

    it "logs monitor delete event publishing to events subscriber" do
      subcriber = Ragios::Events::Subscriber.new
      future = subcriber.future.receive
      @manager.log_monitor(:delete, "monitor_id")
      received = JSON.parse(future.value, symbolize_names: true)
      expect(received).to include(
        monitor_id: "monitor_id",
        event: {:"monitor status" => "deleted"},
        state: "deleted",
        type: "event",
        event_type: "monitor.delete"
      )
    end

     it "logs monitor update event publishing to events subscriber" do
      subcriber = Ragios::Events::Subscriber.new
      future = subcriber.future.receive
      @manager.log_monitor(:update, "monitor_id", update: {monitor: "updated options"})
      received = JSON.parse(future.value, symbolize_names: true)
      expect(received).to include(
        monitor_id: "monitor_id",
        event: {:"monitor status" => "updated"},
        state: "updated",
        type: "event",
        event_type: "monitor.update",
        update: {monitor: "updated options"}
      )
    end
  end
end
