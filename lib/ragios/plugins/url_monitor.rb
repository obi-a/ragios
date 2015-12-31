# Plugin: Monitors a URL by sending a http GET request to it
# the test PASSES if it gets a HTTP 200, 301 or 302 Response status code from the http request

module Ragios
  module Plugin

    class UrlMonitor
      attr_reader :test_result
      attr_reader :url
      attr_reader :connection
      attr_reader :retry_limit
      attr_reader :connect_timeout

      def init(monitor)
        @url = monitor[:url]
        @retry_limit = monitor[:retry_limit]
        @connect_timeout = monitor[:connect_timeout]
        raise "A url must be provided for url_monitor in #{monitor[:monitor]} monitor" if @url.nil?
      end

      def test_command?
        @connection = Excon.new(@url)
        options = {
          expects: [200, 301, 302],
          method: :get,
          idempotent: true
        }

        options[:retry_limit] = @retry_limit || 3
        options[:connect_timeout] = @connect_timeout || 60
        response = @connection.request(options)
        @test_result = { "HTTP GET Request to #{@url}" => response.status }
        return true
      rescue => e
        @test_result = { "HTTP GET Request to #{@url}" => e.message }
        return false
      end
    end
  end
end
