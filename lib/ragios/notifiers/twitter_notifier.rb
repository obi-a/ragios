module Ragios
  module Notifier
    class TwitterNotifier
      def initialize(monitor=nil)
        @monitor = monitor
      end
      def self.config(twitter_cred)
        @@twitter_consumer_key = twitter_cred[:consumer_key]
        @@twitter_consumer_secret = twitter_cred[:consumer_secret]
        @@twitter_access_token = twitter_cred[:access_token]
        @@twitter_access_secret = twitter_cred[:access_secret]  
      end

      def tweet message
        Twitter.configure do |config|
  	  config.consumer_key = @@twitter_consumer_key
  	  config.consumer_secret =  @@twitter_consumer_secret
  	  config.oauth_token = @@twitter_access_token
  	  config.oauth_token_secret = @@twitter_access_secret
        end 
        Twitter.update message.slice!(0..138) #140 character limit on twitter  
      end

      def message template
        message_template = ERB.new File.new($path_to_messages + "/"+ template ).read
        message_template.result(binding)
      end

      def resolved
        tweet(message("tweet_resolved.erb"))
      end

      def notify
        tweet(message("tweet_notify.erb"))
      end
    end
  end
end
