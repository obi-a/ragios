require 'spec_base.rb'

describe Ragios::Events::Receiver do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @receiver = Ragios::Events::Receiver.new
  end

  context "when it is initialized" do

    it "connects to a zmq_dealer socket" do
      expect(@receiver.socket).to be_a(Celluloid::ZMQ::Socket::Dealer)
    end

    it "binds to the link" do
      expect(@receiver.action).to eq(:bind_link)
    end

    it "binds to events_receiver link" do
      expect(@receiver.link).to eq(Ragios::SERVERS[:events_receiver])
    end

    it "creates a callback to handle messages" do
      expect(@receiver.handler).to be_a(Proc)
    end

  end
end
