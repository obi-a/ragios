require 'spec_base.rb'

describe Ragios::Events::Publisher do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @publisher = Ragios::Events::Publisher.new
    @event = {
      monitor_id: "586ad8aa-bc29-41a1-935b-f48031c72d90",
      event: {},
      state: "triggered",
      time: "2017-08-28T01:06:10Z",
      type: "event",
      event_type: "monitor.triggered"
    }
  end
  context "when it publishes an event of event_type:  monitor" do
    it "the event is received by the events subscriber" do
      subscriber = Ragios::Events::Subscriber.new
      future  = subscriber.future.receive
      @publisher.log_event(@event)
      received = future.value
      received_event = JSON.parse(received, symbolize_names: true)
      expect(received_event).to eq(@event)
    end
  end

  context "when it is initialized" do
    it "connects to a zmq_publisher socket" do
      expect(@publisher.socket).to be_a(Celluloid::ZMQ::Socket::Pub)
    end
    it "connects to the link" do
      expect(@publisher.action).to eq(:connect_link)
    end
    it "connects to events_subscriber link" do
      expect(@publisher.link).to eq(Ragios::SERVERS[:events_subscriber])
    end
  end

  describe "logging events" do
    context "when a valid event is provided" do
      describe "#log_event!" do
        it "logs the event closes the socket & terminates the publisher actor" do
          socket = @publisher.socket
          @publisher.log_event!(@event)
          expect{@publisher.socket}.to raise_error(/No live threads left. Deadlock?/)
        end
      end
      describe "#log_event" do
        it "logs event and does not terminate the actor" do
          @publisher.log_event(@event)
          expect{@publisher.socket}.not_to raise_error
        end
      end
    end
    context "when a valid event is not provided" do
      context "when event is not a hash" do
        it "raises an argument error" do
          expect{ @publisher.log_event(:symbol) }.to raise_error(ArgumentError)
        end
      end
      context "when event does not contain monitor_id" do
        it "raises a KeyError" do
          expect{ @publisher.log_event(event_type: "monitor.stopped") }.to raise_error(KeyError)
        end
      end
      context "when event does not contain event_type" do
        it "raises a KeyError" do
          expect{ @publisher.log_event(monitor_id: SecureRandom.uuid) }.to raise_error(KeyError)
        end
      end
    end
  end
end