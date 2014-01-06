require 'pony'

module Ragios
  module Notifier
    class Sendmail
      include Ragios::EmailNotifier
      #sends email notifications with the pony gem via sendmail
      def deliver(message)
        #sample message
        #message = {:to => "admin@example.com",
        #           :subject =>"subj",
        #           :body => "stuff"}
        Pony.mail message
      end
    end
  end
end

