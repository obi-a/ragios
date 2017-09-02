require 'spec_base.rb'

describe Ragios::RecurringJobs::Pusher do
  before (:each) do
    Celluloid.shutdown; Celluloid.boot
    @pusher = Ragios::RecurringJobs::Pusher.new
  end

  context "when it pushes a message" do
    it "the message is received by the recurring_jobs receiver" do
      message = "This is a message"
      receiver = Ragios::RecurringJobs::Receiver.new
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
    it "connects to recurring_jobs_receiver link" do
      expect(@pusher.link).to eq(Ragios::SERVERS[:recurring_jobs_receiver])
    end
  end
end
