module Ragios 
module Schedulers

class Server
    
    attr :monitors #list of long running monitors 

    #create the monitors and add them to the database
    def create(monitors)
         @monitors = monitors 
         Couchdb.create 'monitors'
         Couchdb.create 'stats'
         
         @monitors.each do |monitor|
            monitor.creation_date = Time.now.to_s(:long) 
            monitor.id = UUIDTools::UUID.random_create.to_s
           #create the monitors database
           doc = {:database => 'monitors', :doc_id => monitor.id, :data => monitor.options}
           Document.create doc
           #create the stats database
           data = {:creation_date => monitor.creation_date}
           doc = {:database => 'stats', :doc_id => monitor.id, :data => data }
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

 def restart(monitors)
  @monitors = monitors

  #read up the stats from database and add the stats values to the object   
  @monitors.each do |monitor|
     monitor.id = monitor.options[:_id]
     doc = {:database => 'stats', :doc_id => monitor.id}
     hash = Couchdb.view doc
     monitor.tag = hash["tag"]
     monitor.time_of_last_test = hash["time_of_last_test"]
     monitor.num_tests_passed = hash["num_tests_passed"].to_i
     monitor.num_tests_failed = hash["num_tests_failed"].to_i
     monitor.total_num_tests = hash["total_num_tests"].to_i
     monitor.creation_date = hash["creation_date"]
  end    

   start
 end
   
 def start  
    #schedule all the monitors to execute test_command() at every time_interval
   scheduler = Rufus::Scheduler.start_new 
   @monitors.each do |monitor|
     
    scheduler.every monitor.time_interval do
     begin 
       monitor.time_of_last_test = Time.now.to_s(:long)  
       if monitor.test_command 
           monitor.num_tests_passed = monitor.num_tests_passed + 1
           #set to nil since the monitor passed
           monitor.has_failed = nil #FALSE
       else
           monitor.num_tests_failed = monitor.num_tests_failed + 1
           
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
      doc = {:database => 'stats', :doc_id => monitor.id}
      hash = Couchdb.view doc
          
      #update document with latest stats on the monitor
       if monitor.has_failed == TRUE 
          status = "FAILED" 
       else 
          status = "PASSED"
      end 
        
      data = { 
         :tag => monitor.tag,  
         :every => monitor.time_interval,
         :test => monitor.test_description, 
         :contact => monitor.contact,
         :describe_test_result => monitor.describe_test_result,
         :creation_date => hash["creation_date"],
         :time_of_last_test => monitor.time_of_last_test.to_s,
         :num_tests_passed => monitor.num_tests_passed.to_s,
         :num_tests_failed => monitor.num_tests_failed.to_s,
         :total_num_tests => monitor.total_num_tests.to_s,
         :last_test_result => monitor.test_result.to_s, 
         :status => status,
         :_rev=> hash["_rev"]}

       doc = {:database => 'stats', :doc_id => monitor.id, :data => data}
       Document.edit doc
               
     end #end of scheduler
    end  
 end #end of start

 end # end of class
 end
end





