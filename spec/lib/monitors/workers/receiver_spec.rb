require 'spec_base.rb'

describe Ragios::Monitors::Workers::Receiver do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @receiver = Ragios::Monitors::Workers::Receiver.new
  end

  context "when it is initialized" do
    it "connects to a zmq_dealer socket" do
      expect(@receiver.socket).to be_a(Celluloid::ZMQ::Socket::Dealer)
    end
    it "connects to the link" do
      expect(@receiver.action).to eq(:connect_link)
    end
    it "connects to workers_pusher link" do
      expect(@receiver.link).to eq(Ragios::SERVERS[:workers_pusher])
    end
    it "creates a callback to handle messages" do
      expect(@receiver.handler).to be_a(Proc)
    end
  end
end