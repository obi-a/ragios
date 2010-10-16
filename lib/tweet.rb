require 'rubygems'
require 'twitter'

#this class hides the messy details of tweeting from rest of the system
class Tweet

  def initialize 

      oauth = Twitter::OAuth.new('Consumer Key', 'Consumer secret')
      oauth.authorize_from_access('access token', 'access secret')   
          
       @client = Twitter::Base.new(oauth) 
  end

  def init(consumer,access)  
      oauth = Twitter::OAuth.new(consumer["consumer_key"], consumer["consumer_secret"])
      oauth.authorize_from_access(access["access_token"], access["access_secret"])     

      @client = Twitter::Base.new(oauth)  
  end
 
  def tweet message
      
      @client.update(message)    
  end

end
