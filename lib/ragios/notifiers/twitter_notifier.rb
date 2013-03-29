module Ragios

#this class hides the messy details of tweeting from rest of the system
class TwitterNotifier

 def self.config(twitter_cred)
     @@consumer_key = twitter_cred[:consumer_key]
     @@consumer_secret = twitter_cred[:consumer_secret]
     @@access_token = twitter_cred[:access_token]
     @@access_secret = twitter_cred[:access_secret]  
 end

  def tweet message
     Twitter.configure do |config|
  	config.consumer_key = @@consumer_key
  	config.consumer_secret =  @@consumer_secret
  	config.oauth_token = @@access_token
  	config.oauth_token_secret = @@access_secret
     end 
   
     Twitter.update message.slice!(0..138) #140 character limit on twitter  
  end

 end
end
