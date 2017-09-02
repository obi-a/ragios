require 'spec_base.rb'

describe Ragios::Monitors::Workers::Pusher do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @pusher = Ragios::Monitors::Workers::Pusher.new
  end

  context "when it pushes a message" do
    it "the message is received by the Workers receiver" do
      monitor_id = "monitor_id"
      receiver = Ragios::Monitors::Workers::Receiver.new
      future  = receiver.future.receive
      @pusher.push(monitor_id)
      received = future.value
      expect(received).to eq([monitor_id])
    end
  end

  context "when it is initialized" do
    it "connects to a zmq_dealer socket" do
      expect(@pusher.socket).to be_a(Celluloid::ZMQ::Socket::Dealer)
    end
    it "binds to the link" do
      expect(@pusher.action).to eq(:bind_link)
    end
    it "binds to workers_pusher link" do
      expect(@pusher.link).to eq(Ragios::SERVERS[:workers_pusher])
    end
  end
end