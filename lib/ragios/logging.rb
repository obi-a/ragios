module Ragios
  class Logging
    class << self
      def setup(options = {})
        device = options[:log_device] || STDOUT
        level = options[:log_level] || :debug
        program_name = options[:program_name] || "Ragios"
        @logger = ::Logger.new(device, progname: program_name, level: level)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime}] #{severity} -- #{progname}: #{msg}\n"
        end
        @logger
      end

      def logger
        defined?(@logger) ? @logger : setup
      end
    end
  end
end
