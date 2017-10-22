require 'aws/ses'

module Ragios
  module Notifiers
    class Ses
      include Ragios::EmailNotifier
      def self.config(amazon_account)
        @@aws_access_key = amazon_account[:access_key]
        @@aws_secret_key = amazon_account[:secret_key]
        @@aws_send_from = amazon_account[:send_from]
      end
      def deliver message
        ses = AWS::SES::Base.new(
           :access_key_id     => @@aws_access_key,
           :secret_access_key => @@aws_secret_key)
        ses.send_email ({
             :to        => message[:to],
             :source    => @@aws_send_from,
             :subject   => message[:subject],
             :text_body => message[:body]})
      end
    end
  end
end
