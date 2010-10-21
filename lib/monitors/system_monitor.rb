require 'rubygems'
require 'pony'
require 'lib/notifiers/tweet_notifier'
require 'lib/notifiers/email_notifier'

#base class that defines the behavior of all system monitors
class SystemMonitor

    # a short description of the test performed by this system monitor
   attr_reader :test_description  
   
   #hostname of the system being monitored
   attr_reader :hostname 

   #ip address of the system being monitored   
   attr_reader :address   
   
   #email address of admin to contact when a test fails
   attr_reader :contact   
   
   #results of a test
   attr_reader :test_result 
  
    #describes the test result, this gives technical details on the test_result
    #This gives the sysadmin info on the technical details of the test results
    attr_reader :describe_test_result
    
    #Time interval to run a test on the system, the test is defined on test_command()
    #Time interval can be expressed in minutes,seconds,hours or combinations of either
    #example 3m = 3 minutes, 10s = 10 seconds, 5h = 5 hours, 4h30m = 4 hours 30 minutes
    # @time_interval = 3m means that the SystemMonitor runs the test every 3minutes
    attr_reader :time_interval

    attr_reader :notification_interval

    #attribute set to TRUE when a test fails and nil otherwise
    attr_accessor :has_failed
    
  
   def initialize 
   end
  
   #defines the tests to run on a system
   def test_command
   end
   
   #defines the action to take when a test fails 
   #- May send email, SMS or tweet to the system admin
   #- May also take action to fix the issue like restart a process/service 
   def failed
       
   end

   def notify
      #email_nofiy
      #tweet_notify
   end

   #this method is invoked when a test_command() or failed() method encounters an exception
   #The aim is to inform the system Admin about the exception while the system keeps on running
   def error_handler
      
   end
   
  def tweet_notify
     
     message = @test_description + " FAILED!  " + @describe_test_result + " = " + @test_result + " Created on: "+ Time.now.to_s

     TweetNotifier.new.tweet message
  end


   def email_notify
   
       puts 'sending mail alert...'
       message = {:to => @contact,
                  :subject =>@test_description + " FAILED", 
                  :body => @test_description + " FAILED \n\n" + @describe_test_result + " = " + @test_result +  "\n\n Created on: " + Time.now.to_s}

       EmailerNotifier.new.send message
      
       
      
   end
     
   #informs a system admin via twitter when a test_command() or failed() method encounters an excepion
   def tweet_error
        message = @test_description + " ERROR: " + $!  + " Created on: "+ Time.now.to_s 
        TweetNotifier.new.tweet message
   end
   
   #informs a system admin via email when a test_command() or failed() method encounters an excepion
   def email_error
       #not yet implemented
   end
     
end


