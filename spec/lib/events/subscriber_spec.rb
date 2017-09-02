require 'spec_base.rb'

describe Ragios::Events::Subscriber do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @subscriber = Ragios::Events::Subscriber.new
  end

  context "when it is initialized" do
    it "connects to a zmq_subscriber socket" do
      expect(@subscriber.socket).to be_a(Celluloid::ZMQ::Socket::Sub)
    end
    it "binds to the link" do
      expect(@subscriber.action).to eq(:bind_link)
    end
    it "binds to events_subscriber link" do
      expect(@subscriber.link).to eq(Ragios::SERVERS[:events_subscriber])
    end
    it "subscribes to the topic monitor" do
      expect(@subscriber.topic).to eq("monitor")
    end
    it "creates a callback to handle messages" do
      expect(@subscriber.handler).to be_a(Proc)
    end

  end
end
