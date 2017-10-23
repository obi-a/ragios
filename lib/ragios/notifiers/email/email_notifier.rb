module Ragios
  module EmailNotifier

    def init(opts = {})
      @monitor = opts
      raise "A contact must be provided for the email notifier in #{@monitor[:monitor]} monitor" unless @monitor[:contact]
    end

    def message template
      message_template = ERB.new(File.new("#{$path_to_messages}/#{template}").read)
      @body = message_template.result(binding)

      @message = {
        :to => @monitor[:contact],
        :subject => @subject,
        :body => @body
      }
    end

    def failed(test_result)
      @test_result = test_result
      deliver(message("email_failed.erb"))
    end

    def resolved(test_result)
      @test_result = test_result
      deliver(message("email_resolved.erb"))
    end

    def error
    end
  end
end
