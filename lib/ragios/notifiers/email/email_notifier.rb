module Ragios
  module EmailNotifier
    def initialize(monitor=nil)
      @monitor = monitor
      raise "A contact must be provided for the email notifier in #{@monitor[:monitor]} monitor" if @monitor[:contact].nil?
    end
    def message template
      message_template = ERB.new(File.new("#{$path_to_messages}/#{template}").read)
      @body = message_template.result(binding)
      @message = {:to => @monitor[:contact],
                  :subject => @subject,
                  :body => @body}
    end
    def failed(monitor)
      @monitor = monitor
      deliver(message("email_failed.erb"))
    end

    def resolved(monitor)
      @monitor = monitor
      deliver(message("email_resolved.erb"))
    end
    def error
    end
  end
end
