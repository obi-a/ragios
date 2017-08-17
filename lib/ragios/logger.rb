module Ragios
  class Logger
    class << self
      def setup(options = {})
        @device = options[:log_device] || STDOUT
        @level = options[:log_level] || :debug
        @program_name = options[:program_name] || "Ragios"
        @logger = ::Logger.new(@device, progname: @program_name, level: @level)

        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime}] #{severity} -- #{progname}: #{msg}\n"
        end
        self
      end

      def log(level, message)
       @logger.send(level, message) if levels.include?(level)
      end

      def level=(level)
        @logger.level = level
      end

      def levels
        [:debug, :info, :warn, :error, :fatal, :unknown]
      end
    end
  end
end
