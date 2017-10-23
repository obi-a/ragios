require 'aws/ses'

module Ragios
  module Notifiers
    class Ses

      include Ragios::EmailNotifier

      attr_reader :ses_mailer, :aws_credentials

      def initialize
        @aws_credentials = {
          access_key: ENV['AWS_ACCESS_KEY_ID'],
          secret_key: ENV['AWS_SECRET_ACCESS_KEY'],
          endpoint: ENV['AWS_SES_ENDPOINT'],
          send_from: ENV['AWS_SES_SEND_FROM']
        }

        @ses_mailer = AWS::SES::Base.new(
          access_key_id: @aws_credentials[:access_key],
          secret_access_key: @aws_credentials[:secret_key],
          server: @aws_credentials[:endpoint]
        )
      end

      def deliver message
        ses_mailer.send_email(
          to:        message[:to],
          source:    @aws_credentials[:send_from],
          subject:   message[:subject],
          text_body: message[:body]
        )
      end
    end
  end
end
