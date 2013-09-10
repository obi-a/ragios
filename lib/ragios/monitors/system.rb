#base class that defines the behavior of all monitors
module Ragios
 
module Monitors

class System

    # a short description of the test performed by this monitor
   attr_reader :test_description  
   
   #hostname of the system being monitored
   attr_reader :hostname 

   #ip address of the system being monitored   
   attr_reader :address   
   
   #email address of admin to contact when a test fails
   attr_reader :contact   
   
   #results of a test
   attr_reader :test_result 
  
    #describes the test result, this gives technical details of the test_result
    #This gives the sysadmin info on the technical details of the test results
    attr_reader :describe_test_result
    
    #Time interval to run a test on the system, the test is defined on test_command()
    #Time interval can be expressed in minutes,seconds,hours or combinations of either
    #example 3m = 3 minutes, 10s = 10 seconds, 5h = 5 hours, 4h30m = 4 hours 30 minutes
    # @time_interval = 3m means that the System runs the test every 3minutes
    attr_reader :time_interval

    attr_reader :notification_interval

    #attribute set to TRUE when a test fails and nil otherwise
    attr_accessor :has_failed
     
    #Real Time Statistics on this monitor
    #total number of times this monitor has been tested since it was created
    attr_accessor :total_num_tests
 
    #total number of tests this monitor has passed since its creation
    attr_accessor :num_tests_passed
    
    #total number of tests this monitor has failed since its creation
    attr_accessor :num_tests_failed

    #time/date this monitor was  created
    attr_accessor :creation_date
    
    #time/date this monitor was last tested by the scheduler
    attr_accessor :time_of_last_test

    #timestamp of last test
    attr_accessor :timestamp

    attr_accessor :status
  
   def initialize 
      @creation_date = Time.now
      @total_num_tests, @num_tests_passed,@num_tests_failed = 0,0,0
      #raise ERROR when the following attributes are not assigned values in a test
      #the attributes must be assigned values by the tests that extend this class
      raise "A description of the test must be specified, @test_description must be assigned a value" if @test_description.nil?
      raise "@describe_test_result must be assigned a value" if @describe_test_result.nil?
      raise "A time interval for running tests must be specified, @time_interval must be assigned a value" if @time_interval.nil?
      raise "An interval for notifications must be specified, @notification_interval must be assigned a value" if @notification_interval.nil?
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
   end
   
   #this method is invoked after test turns from FAILED to PASSED
   # it informs the system admin that the issue has been resolved
   def fixed
   end

   #this method is invoked when a test_command() or failed() method encounters an exception
   #The aim is to inform the system Admin about the exception while the system keeps on running
   def error_handler  
   end     
end

 end #end of module
end #end of module



