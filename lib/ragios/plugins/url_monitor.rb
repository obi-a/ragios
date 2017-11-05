# Plugin: Monitors a URL by sending a http GET request to it
# the test PASSES if it gets a HTTP success Response status code from the http request

require 'excon'

module Ragios
  module Plugins
    class UrlMonitor

      attr_reader :test_result, :url, :connection, :options, :mock

      SUCCESS_STATUSES = [
        200, 201, 202, 301, 302, 307, 308
      ].freeze

      RETRY_COUNT = 3

      CONN_TIMEOUT = 60

      HTTP_METHOD = :get

      def initialize(mock = false)
        @mock = mock
        @options = {}
      end

      def init(monitor = {})
        raise "A url must be provided for url_monitor in #{monitor[:monitor]} monitor" unless monitor[:url]
        @url = monitor.fetch(:url)
        @connection = Excon.new(@url, mock: @mock)

        @options[:idempotent]      = monitor.fetch(:idempotent, true)
        @options[:method]          = monitor.fetch(:method, HTTP_METHOD)
        @options[:expects]         = monitor.fetch(:expects, SUCCESS_STATUSES)
        @options[:retry_limit]     = monitor.fetch(:retry_limit, RETRY_COUNT)
        @options[:connect_timeout] = monitor.fetch(:connect_timeout, CONN_TIMEOUT)

        @options[:body]            = monitor.fetch(:body) if monitor[:body]
        @options[:headers]         = monitor.fetch(:headers) if monitor[:headers]

        true
      end

      def test_command?
        response = @connection.request(@options)
        @test_result = { "HTTP GET Request to #{@url}" => response.status }

        return true
      rescue Excon::Errors::Error => e
        @test_result = { "HTTP GET Request to #{@url}" => e.message }

        return false
      end
    end
  end
end
