module Ragios
#this class hides the messy details of sending notifications via gmail 
#from the rest of the system
class GmailNotifier

  def self.config(gmail_account)
     @@username = gmail_account[:username]
     @@password = gmail_account[:password]  
  end

  def send message
      
       #sample message
      #message = {:to => "admin@example.com",
      #           :subject =>"subj", 
      #           :body => "stuff"}
     gmail = Gmail.connect(@@username, @@password)
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
