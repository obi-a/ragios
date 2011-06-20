module Ragios 
module Schedulers

class Server
    
    attr :monitors #list of long running monitors 

    def initialize(monitors)
         @monitors = monitors 
         Couchdb.create 'monitors'
         
         @monitors.each do |monitor|
           #puts monitor.options.inspect
            monitor.creation_date = Time.now.to_s(:long) 
            monitor.id = UUIDTools::UUID.random_create.to_s
           doc = {:database => 'monitors', :doc_id => monitor.id, :data => monitor.options}
           Document.create doc 
         end
         
    end
    
  #returns a list of all active monitors managed by this scheduler
   def get_monitors
        
   end

   def status_report
       
   end

  

 def init()
 end 
   
 def start  
    #schedule all the monitors to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new 
   @monitors.each do |monitor|
   
     #reset this value to ensure that a monitor that failed the init() test will still be tracked properly
     monitor.has_failed = nil #FALSE

    scheduler.every monitor.time_interval do
     begin 
       monitor.time_of_last_test = Time.now.to_s(:long)  
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
          #puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
          monitor.has_failed = TRUE
          monitor.error_handler
      end
       #count this test
       monitor.total_num_tests = monitor.total_num_tests + 1 
      
      #get this monitor's document from the database 
      doc = {:database => 'monitors', :doc_id => monitor.id}
      hash = Couchdb.find doc
          
      #update document with latest stats on the monitor
       if monitor.has_failed == TRUE 
          status = "PASSED" 
       else 
          status = "FAILED"
      end 
        
      data = { 
         :time_of_last_test => monitor.time_of_last_test.to_s,
         :num_tests_passed => monitor.num_tests_passed.to_s,
         :num_tests_failed => monitor.num_tests_failed.to_s,
         :total_num_tests => monitor.total_num_tests.to_s,
         :last_test_result => monitor.test_result.to_s, 
         :status => status,
         :_rev=> hash["_rev"]}
       
         #puts data.inspect

       doc = {:database => 'monitors', :doc_id => monitor.id, :data => data}
       #Document.edit doc
               
     end #end of scheduler
    end  
 end #end of start

 end # end of class
 end
end





