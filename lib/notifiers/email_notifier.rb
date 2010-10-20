require 'rubygems'
require 'pony'

#this class hides the messy details of sending email notifications from rest of the system
class EmailNotifier

  def initialize 
 
  end

  #sends email notifications with the pony gem via sendmail
  def send message
     
      #sample message
      #message = {:to => "admin@example.com",
      #           :subject =>"subj", 
      #           :body => "stuff"}
     Pony.mail message
     
  end   

end


