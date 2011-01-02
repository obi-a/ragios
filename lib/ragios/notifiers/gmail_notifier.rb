

module Ragios
module Notifiers

#this class hides the messy details of sending notifications via gmail 
#from the rest of the system
class GMailNotifier

  def initialize 

       @username = 'gmail_username'  #replace with gmail username
       @password =  'gmail_password' #replace with gmail password 
  end

  def send message
      
       #sample message
      #message = {:to => "admin@example.com",
      #           :subject =>"subj", 
      #           :body => "stuff"}

     gmail = Gmail.connect(@username, @password)
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
