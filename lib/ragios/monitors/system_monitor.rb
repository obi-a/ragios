
#base class that defines the behavior of all system monitors

module Ragios
 
module Monitors

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
      #raise ERROR when the following attributes are not assigned values in a test
      #the attributes must be assigned values by the tests that extend this class
      raise "@test_description must be assigned a value" if @test_description.nil?
      raise "@describe_test_result must be assigned a value" if @describe_test_result.nil?
      raise "@contact must be assigned a value" if @contact.nil?
      raise "@time_interval must be assigned a value" if @time_interval.nil?
      raise "@notification_interval must be assigned a value" if @notification_interval.nil?
   end
  
   #defines the tests to run on a system
   def test_command
   end
   
   #defines the action to take when a test fails 
   #- May take action to fix the issue like restart a process/service 
   def failed
       
   end
   
   #this method is invoked after a test fails
   #it sends a notification to the system admin about a failed test via email,twitter or any other specified notifier
   def notify   
      gmail_notify
      #email_notify
      #tweet_notify
   end
   
   #this method is invoked after test turns from FAILED to PASSED
   # it should inform the system admin that the issue has been resolved
   def fixed
      
   end

   #this method is invoked when a test_command() or failed() method encounters an exception
   #The aim is to inform the system Admin about the exception while the system keeps on running
   def error_handler
      
   end

  def gmail_notify
      
     puts 'sending gmail alert...'
       message = {:to => @contact,
                  :subject =>@test_description + " FAILED", 
                  :body => @test_description + " FAILED \n\n" + @describe_test_result + " = " + @test_result +  "\n\n Created on: " + Time.now.to_s}

      Ragios::Notifiers::GMailNotifier.new.send message

  end
   
  def tweet_notify
     
     message = @test_description + " FAILED!  " + @describe_test_result + " = " + @test_result + " Created on: "+ Time.now.to_s

      Ragios::Notifiers::TweetNotifier.new.tweet message
  end


   def email_notify
   
       puts 'sending mail alert...'
       message = {:to => @contact,
                  :subject =>@test_description + " FAILED", 
                  :body => @test_description + " FAILED \n\n" + @describe_test_result + " = " + @test_result +  "\n\n Created on: " + Time.now.to_s}

      Ragios::Notifiers::EmailNotifier.new.send message
       
   end
     
   #informs a system admin via twitter when a test_command() or failed() method encounters an excepion
   def tweet_error
        message = @test_description + " ERROR: " + $!  + " Created on: "+ Time.now.to_s 
         Ragios::Notifiers::TweetNotifier.new.tweet message
   end
   
   #informs a system admin via email when a test_command() or failed() method encounters an excepion
   def email_error
       #not yet implemented
   end
     
end

 end #end of module
end #end of module



