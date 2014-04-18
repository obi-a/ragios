require 'spec_base.rb'
require 'notifier_test_setup.rb'

describe Ragios::Notifier::TwitterNotifier do
  it "tests a monitor" do
    Ragios::NotifierTest::failed_resolved('Twitter test','twitter_notifier')
  end

  it "should send a tweet a notification message " do
       Ragios::Notifier::TwitterNotifier.new.tweet "Test notification message from Ragios via twitter. " + "Created on: " + Time.now.to_s
  end
end
