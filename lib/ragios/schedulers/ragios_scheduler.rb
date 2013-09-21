
module Ragios 
module Schedulers

class RagiosScheduler
    
    attr :monitors #list of long running monitors

    def initialize(monitors)
         @monitors = monitors 
    end
    
  #returns a list of all active monitors managed by this scheduler
   def get_monitors
        return @monitors
   end



   def init()
     
       	puts "Ragios: Initializing"

	count = 1
	puts @monitors.length.to_s + " Monitors detected"
	puts "\n"

	@monitors.each do |monitor|
 		puts "test " + count.to_s + ". "+  monitor.test_description 
 		puts "Scheduled to run every " + monitor.time_interval + "\n"
 		puts "Running First Test..."
	begin 
          monitor.time_of_last_test = Time.now 
 	  if monitor.test_command
           monitor.num_tests_passed = monitor.num_tests_passed + 1
           monitor.has_failed = nil #FALSE
           puts  "  [PASSED]" + " Created on: "+ Time.now.to_s(:long) 
           puts monitor.describe_test_result + " = " + monitor.test_result.to_s
  	  else
           monitor.num_tests_failed = monitor.num_tests_failed + 1
           monitor.has_failed = TRUE
           puts "  [FAILED]" + " Created on: "+ Time.now.to_s(:long) 
           puts monitor.describe_test_result + " = " + monitor.test_result.to_s
           monitor.failed
  	  end
   	   puts "\n"
	rescue Exception
   	   puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
           monitor.error_handler
           raise
        end
       count = count + 1
       monitor.total_num_tests = monitor.total_num_tests + 1 
       end  
   end 
   
 def start
   #schedule all the monitors to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new 
   @monitors.each do |monitor|
 
     #reset this value to ensure that a monitor that failed the init() test will still be tracked properly
     monitor.has_failed = nil #FALSE

    scheduler.every monitor.time_interval do
     begin 
       monitor.time_of_last_test = Time.now 
       if monitor.test_command 
           monitor.num_tests_passed = monitor.num_tests_passed + 1
           #set to nil since the monitor passed
           monitor.has_failed = nil #FALSE
           puts monitor.test_description + "   [PASSED]" + " Created on: "+ Time.now.to_s(:long)
       else
           monitor.num_tests_failed = monitor.num_tests_failed + 1
           puts monitor.test_description +   "   [FAILED]" + " Created on: "+ Time.now.to_s(:long)
           
               #if the failed monitor has been marked as failed
               #this prevents the system from scheduling a new notification scheduler when one is already scheduled
               if monitor.has_failed
                   #do nothing
               else 

                   monitor.failed  

                   #if failed monitor has not been marked as failed, then mark it as failed
                   monitor.has_failed = TRUE
 
                   #send out first notification
                   monitor.notify    
                 
                   #setup notification scheduler
                   #this scheduler will schedule the notifcations to be sent out at the specified notification interval
                  Ragios::Schedulers::NotificationScheduler.new(monitor).start
 
               end 
       end
       #catch all exceptions
      rescue Exception
          puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
          monitor.has_failed = TRUE
          monitor.error_handler
      end
       #count this test
       monitor.total_num_tests = monitor.total_num_tests + 1 
     end #end of scheduler

    end  
  end

end

 end
end
