module Ragios
#this class hides the messy details of sending notifications via Amazon Simple Email Service
#from the rest of the system
class SESNotifier

  def self.config(amazon_account)
     @@access_key = amazon_account[:access_key]
     @@secret_key = amazon_account[:secret_key] 
     @@send_from = amazon_account[:send_from] 
  end

 def send message

  ses = AWS::SES::Base.new(
       :access_key_id     => @@access_key, 
       :secret_access_key => @@secret_key
   )

  ses.send_email ({
             :to        => message[:to],
             :source    => @@send_from,
             :subject   => message[:subject],
             :text_body => message[:body]}
  )

 end

end
end
