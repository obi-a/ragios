require 'spec_base.rb'

describe Ragios::Plugins::UrlMonitor do
  let(:plugin) do

    options = {
      url: "http://google.com",
      notifier: "log_notifier",
      monitor: "Sample Monitor"
    }

    plugin = Ragios::Plugins::UrlMonitor.new(mock = true)
    plugin.init(options)
    plugin
  end


  describe "#init" do

    it "initializes the plugin with defualt settings" do
      expect(plugin.options).to eq(
        idempotent: true,
        method: Ragios::Plugins::UrlMonitor::HTTP_METHOD,
        expects: Ragios::Plugins::UrlMonitor::SUCCESS_STATUSES,
        retry_limit: Ragios::Plugins::UrlMonitor::RETRY_COUNT,
        connect_timeout: Ragios::Plugins::UrlMonitor::CONN_TIMEOUT
      )

      expect(plugin.url).to eq("http://google.com")
    end
  end

  describe "#test_command?" do

    context "when request to the url returns an OK response code" do
      before(:each) do
        Excon.stub({}, {:body => 'body', :status => 200})
      end

      it "returns true and sets the correct results" do
        expect(plugin.test_command?).to be_truthy

        expect(plugin.test_result).to eq(
          "HTTP GET Request to #{plugin.url}" => 200
        )
      end
    end

    context "when request to the url returns an error response code" do
      before(:each) do
        Excon.stub({}, {:body => 'something went wrong', :status => 500})
      end

      it "returns false and sets the correct results" do
        expect(plugin.test_command?).to be_falsey

        expect(plugin.test_result.values.first).to include("500 InternalServerError")
      end
    end
  end
end
