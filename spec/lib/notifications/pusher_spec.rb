require 'spec_base.rb'

describe Ragios::Notifications::Pusher do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @pusher = Ragios::Notifications::Pusher.new
  end

  context "when it pushes a message" do
    it "the message is received by the notifcations receiver" do
      message = "This is a message"
      receiver = Ragios::Notifications::Receiver.new
      future  = receiver.future.receive
      @pusher.push(message)
      received = future.value
      expect(received).to eq([message])
    end
  end

  context "when it is initialized" do
    it "connects to a zmq_dealer socket" do
      expect(@pusher.socket).to be_a(Celluloid::ZMQ::Socket::Dealer)
    end
    it "connects to the link" do
      expect(@pusher.action).to eq(:connect_link)
    end
    it "connects to notifications_receiver link" do
      expect(@pusher.link).to eq(Ragios::SERVERS[:notifications_receiver])
    end
  end
end
