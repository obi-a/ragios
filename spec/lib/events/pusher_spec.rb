require 'spec_base.rb'

describe Ragios::Events::Pusher do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @pusher = Ragios::Events::Pusher.new
    @event = {
      monitor_id: "586ad8aa-bc29-41a1-935b-f48031c72d90",
      event: {},
      state: "triggered",
      time: "2017-08-28T01:06:10Z",
      type: "event",
      event_type: "monitor.triggered"
    }
  end
  context "when it pushes an event of event_type:  monitor" do
    it "the event is received by the events receiver" do
      receiver = Ragios::Events::Receiver.new
      future  = receiver.future.receive

      @pusher.log_event(@event)

      received = future.value
      received_event = JSON.parse(received.first, symbolize_names: true)
      expect(received_event).to eq(@event)
    end
  end

  context "when it is initialized" do
    it "connects to a zmq_dealer socket" do
      expect(@pusher.socket).to be_a(Celluloid::ZMQ::Socket::Dealer)
    end
    it "connects to the link" do
      expect(@pusher.action).to eq(:connect_link)
    end
    it "connects to events_receiver link" do
      expect(@pusher.link).to eq(Ragios::SERVERS[:events_receiver])
    end
  end

  describe "logging events" do
    context "when a valid event is provided" do
      describe "#log_event" do
        it "logs event and does not terminate the actor" do
          @pusher.log_event(@event)
          expect{@pusher.socket}.not_to raise_error
        end
      end
    end
    context "when a valid event is not provided" do
      context "when event is not a hash" do
        it "raises an argument error" do
          expect{ @pusher.log_event(:symbol) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
