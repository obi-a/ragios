require 'spec_base.rb'
require 'notifier_test_setup.rb'

describe Ragios::Notifier::GmailNotifier do

  it "tests a monitor" do
    Ragios::NotifierTest::failed_resolved('Gmail test','gmail_notifier')     
  end

  it "should send a notification message via gmail" do
    message = {:to => ENV['RAGIOS_CONTACT'],
               :subject =>"Test notification message from Ragios via gmail", 
               :body => "stuff"}
    Ragios::Notifier::GmailNotifier.new.deliver message
  end
end