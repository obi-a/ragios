

module Ragios
module Notifiers

#this class hides the messy details of tweeting from rest of the system
class TweetNotifier

  def initialize 

      oauth = Twitter::OAuth.new('Consumer Key', 'Consumer secret')
      oauth.authorize_from_access('access token', 'access secret')   
          
       @client = Twitter::Base.new(oauth) 
  end

  def tweet message
      
      @client.update message.slice!(0..139) #140 character limit on twitter  
  end

end

 end
end
