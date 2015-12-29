require 'spec_base.rb'

#testing a https url
https_url = { url: "https://www.google.com/" }

#testing a regular url
regular_url = { url: "http://www.google.com" }

#testing a failing url
failing_url = { url: "http://www.google.com/fail/" }

multiple_retry_monitor = {
  url: "http://www.google.com/fail/",
  retry_limit: 2,
  connect_timeout: 300
}

#testing with no url
no_url = {}

describe Ragios::Plugin::UrlMonitor do
  it "should send a http GET request to the url and pass" do
    regular_url_plugin = Ragios::Plugin::UrlMonitor.new
    regular_url_plugin.init(regular_url)
    regular_url_plugin.test_command?.should == true
    regular_url_plugin.test_result.should == {
      "HTTP GET Request to #{regular_url[:url]}" => 200
    }
  end

  it "should send a http GET request to the url and fail" do
    failing_plugin = Ragios::Plugin::UrlMonitor.new
    failing_plugin.init(failing_url)
    failing_plugin.test_command?.should ==  false
    failing_plugin.test_result.should == {
      "HTTP GET Request to http://www.google.com/fail/" => "Expected([200, 301, 302]) <=> Actual(404 Not Found)\n"
    }
  end

  it "should send a https GET request to the url and pass" do
    https_url_plugin = Ragios::Plugin::UrlMonitor.new
    https_url_plugin.init(https_url)
    https_url_plugin.test_command?.should == true
    https_url_plugin.test_result.should == {
      "HTTP GET Request to #{https_url[:url]}" => 200
    }
  end

  it "should send a https GET request to the url and pass" do
    mulitple_retry_plugin = Ragios::Plugin::UrlMonitor.new
    mulitple_retry_plugin.init(multiple_retry_monitor)
    mulitple_retry_plugin.test_command?.should == false
  end

  it "should raise error when no url is provided" do
    expect { Ragios::Plugin::UrlMonitor.new.init(no_url) }.to raise_error
  end
end
