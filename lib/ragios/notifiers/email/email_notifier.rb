module Ragios
  module EmailNotifier
    def initialize(monitor=nil)
      @monitor = monitor
    end
    def message template
      message_template = ERB.new(File.new("#{$path_to_messages}/#{template}").read)
      @body = message_template.result(binding)
      @message = {:to => @monitor[:contact],
                  :subject => @subject,
                  :body => @body}
    end
    def failed
      deliver(message("email_failed.erb"))
    end

    def resolved
      deliver(message("email_resolved.erb"))
    end
    def error
    end
  end
end
