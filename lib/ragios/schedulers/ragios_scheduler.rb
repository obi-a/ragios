
module Ragios 
module Schedulers

class RagiosScheduler
    
    attr :monitors 
    attr :start_time

    def initialize(monitors)
         @monitors = monitors
         #time since the first status report -- will be from the time Ragios started running -- see status_report.erb
         @start_time  =  Time.now
    end
    
  #returns a list of all active monitors managed by this scheduler
   def get_monitors
        return @monitors
   end

   def status_report
       message_template = ERB.new File.new($path_to_messages + "/status_report.erb" ).read
       begin 
       message_template.result(binding)
       rescue FloatDomainError
           #KNOWN ISSUE: to be fixed later
           raise 'Error Generating Status Report: At least one Monitor has total_number_of_tests_performed  = 0' 
       end
   end

  #send a report  with stats and status information on all active monitors to the system admin via email
  def update_status config

      #format of config {}
      #config  = {   :every => '1d',
         #          :contact => 'admin@mail.com',
          #         :via => 'gmail'
           #       }

    scheduler = Rufus::Scheduler.start_new
    scheduler.every config[:every] do 

        puts 'sending Status Report...' 

        @body = status_report  
        message = {:to => config[:contact],
                  :subject => @subject, 
                  :body => @body}

      if config[:via] == 'gmail'
           Ragios::GmailNotifier.new.send message   
        elsif config[:via] == 'email'
           Ragios::Notifiers::EmailNotifier.new.send message
        else
           raise 'Wrong hash parameter for update_status()'
     end
    end
 end

   def init
       	puts "Welcome to Ragios"
       	puts "Initializing"

	count = 1
	puts @monitors.length.to_s + " Monitors detected"
	puts "\n"

	@monitors.each do |job|
 		puts "test " + count.to_s + ". "+  job.test_description 
 		puts "Scheduled to run every " + job.time_interval + "\n"
 		puts "Running First Test..."
	begin 
          job.time_of_last_test = Time.now 
 	  if job.test_command
           job.num_tests_passed = job.num_tests_passed + 1
           job.has_failed = nil #FALSE
           puts  "  [PASSED]" + " Created on: "+ Time.now.to_s(:long) 
           puts job.describe_test_result + " = " + job.test_result.to_s
  	  else
           job.num_tests_failed = job.num_tests_failed + 1
           job.has_failed = TRUE
           puts "  [FAILED]" + " Created on: "+ Time.now.to_s(:long) 
           puts job.describe_test_result + " = " + job.test_result.to_s
           job.failed
  	  end
   	   puts "\n"
	rescue Exception
   	   puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
           job.error_handler
           raise
        end
       count = count + 1
       job.total_num_tests = job.total_num_tests + 1 
       end  
   end 
   
 def start
   #schedule all the monitors to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new 
   @monitors.each do |job|
 
     #reset this value to ensure that a monitor that failed the init() test will still be tracked properly
     job.has_failed = nil #FALSE

    scheduler.every job.time_interval do
     begin 
       job.time_of_last_test = Time.now 
       if job.test_command 
           job.num_tests_passed = job.num_tests_passed + 1
           #set to nil since the job passed
           job.has_failed = nil #FALSE
           puts job.test_description + "   [PASSED]" + " Created on: "+ Time.now.to_s(:long)
       else
           job.num_tests_failed = job.num_tests_failed + 1
           puts job.test_description +   "   [FAILED]" + " Created on: "+ Time.now.to_s(:long)
           
               #if the failed job has been marked as failed
               #this prevents the system from scheduling a new notification scheduler when one is already scheduled
               if job.has_failed
                   #do nothing
               else 

                   job.failed  

                   #if failed job has not been marked as failed, then mark it as failed
                   job.has_failed = TRUE
 
                   #send out first notification
                   job.notify    
                 
                   #setup notification scheduler
                   #this scheduler will schedule the notifcations to be sent out at the specified notification interval
                  Ragios::Schedulers::NotificationScheduler.new(job).start
 
               end 
       end
       #catch all exceptions
      rescue Exception
          puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
          job.has_failed = TRUE
          job.error_handler
      end
       #count this test
       job.total_num_tests = job.total_num_tests + 1 
     end #end of scheduler
    end  
  end

end

 end
end

