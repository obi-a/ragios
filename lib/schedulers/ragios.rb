require 'rufus/scheduler'

#
class Ragios
    
    attr :jobs

    def initialize(jobs)
         @jobs = jobs  
    end

   def init
       	puts "Welcome to Ragios"
       	puts "Initializing"

	count = 1
	puts @jobs.length.to_s + " jobs detected"
	puts "\n"

	@jobs.each do |job|
 		puts "Job " + count.to_s + ". "+  job.test_description 
 		puts "Scheduled to run every " + job.time_interval + "\n"
 		puts "Running First Test..."
	begin 
 	  if job.test_command
           puts  "  [PASSED]" + " Created on: "+ Time.now.to_s 
           puts job.describe_test_result + " = " + job.test_result
  	  else
           puts "  [FAILED]" + " Created on: "+ Time.now.to_s 
           puts job.describe_test_result + " = " + job.test_result
           job.failed
      
  	  end
   	   puts "\n"
	rescue Exception
   	   puts "ERROR: " +  $!  + " Created on: "+ Time.now.to_s 
            raise
           job.error_handler
        end
       count = count + 1
       end  
   end 
    
 def trap_exit   
    #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
 end  

 def start
    
   #schedule all the jobs to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new
   @jobs.each do |job|
    scheduler.every job.time_interval do
     begin  
       if job.test_command
           puts job.test_description + "   [PASSED]" + " Created on: "+ Time.now.to_s
       else
           puts job.test_description +   "   [FAILED]" + " Created on: "+ Time.now.to_s
           job.failed
       end
       #catch all exceptions
      rescue Exception
          puts "ERROR: " +  $!  + " Created on: "+ Time.now.to_s 
          job.error_handler
      end
     end #end of scheduler
    end 
    trap_exit      
  end

end

