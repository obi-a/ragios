module Ragios
  module Notifier
    class GmailNotifier
      include Ragios::EmailNotifier
      def self.config(gmail_account)
        @@gmail_username = gmail_account[:username]
        @@gmail_password = gmail_account[:password]  
      end
      def deliver message
        #sample message
        #message = {:to => "admin@example.com",
        #           :subject =>"subj", 
        #           :body => "stuff"}
        gmail = Gmail.connect(@@gmail_username, @@gmail_password)
        # play with your gmail...
        gmail.deliver do
          to message[:to]
          subject message[:subject]
          text_part do
            body message[:body]
          end
        end
        gmail.logout
      end
    end
  end
end
