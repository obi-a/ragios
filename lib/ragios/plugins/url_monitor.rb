#Plugin: Monitors a URL by sending a http GET request to it
#the test PASSES if it gets a HTTP 200,301 or 302 Response status code from the http request
module Ragios
  module Plugin

    class UrlMonitor
      attr_reader :test_result
      attr_reader :url

      def init(monitor)
        @url = monitor[:url]
        raise "A url must be provided for url_monitor in #{monitor[:monitor]} monitor" if @url.nil?
      end

      def test_command
        response = RestClient.get @url, {"User-Agent" => "Ragios (Saint-Ruby)"}
        @test_result = {"HTTP GET Request to #{@url}" => response.code}
        return true
      rescue => e
        @test_result = {"HTTP GET Request to #{@url}" => e.message }
        return false
      end
    end

  end
end


