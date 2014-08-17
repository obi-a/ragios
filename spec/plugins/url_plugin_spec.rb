require 'spec_base.rb'

#testing a https url
https_url = { url: 'https://www.google.com/'}

#testing a regular url
regular_url =  { url: 'http://www.google.com'}

#testing a failing url
failing_url  = { url: 'http://www.google.com/fail/'}

#testing with no url
no_url = {}

describe Ragios::Plugin::UrlMonitor do
  it "should send a http GET request to the url and pass" do
    regular_url_plugin = Ragios::Plugin::UrlMonitor.new
    regular_url_plugin.init(regular_url)
    regular_url_plugin.test_command?.should == true
  end

  it "should send a http GET request to the url and fail" do
    failing_plugin = Ragios::Plugin::UrlMonitor.new
    failing_plugin.init(failing_url)
    failing_plugin.test_command?.should ==  false
  end

  it "should send a https GET request to the url and pass" do
    https_url_plugin = Ragios::Plugin::UrlMonitor.new
    https_url_plugin.init(https_url)

    https_url_plugin.test_command?.should == true
  end

  it "should raise error when no url is provided" do
    expect { Ragios::Plugin::UrlMonitor.new.init(no_url) }.to raise_error
  end
end
