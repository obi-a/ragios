require 'spec_base.rb'
require 'notifier_test_setup.rb'

describe Ragios::Notifier::Ses do
  it "tests a monitor" do
    Ragios::NotifierTest::failed_resolved('SES test','ses')
  end
  it "should send a notification message via ses" do
    message = {:to => ENV['RAGIOS_CONTACT'],
               :subject =>"Test notification message from Ragios via ses",
               :body => "stuff"}
    Ragios::Notifier::Ses.new(contact:"").deliver message
  end
end
