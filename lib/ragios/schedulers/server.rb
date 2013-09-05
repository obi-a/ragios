module Ragios 
module Schedulers

class Server

    attr :monitors #list of long running monitors 
    attr :scheduler

    def initialize()
     @scheduler = Rufus::Scheduler.start_new 
    end 

    #create the monitors and add them to the database
    def create(monitors)
         auth_session = Ragios::DatabaseAdmin.session
         database_admin = Ragios::DatabaseAdmin.admin
         @monitors = monitors 
         begin
           Couchdb.create Ragios::DatabaseAdmin.monitors,auth_session
         rescue CouchdbException 
         end
         @monitors.each do |monitor|
           monitor.creation_date = Time.now.to_s(:long) 
           monitor.id = UUIDTools::UUID.random_create.to_s
           options = monitor.options.merge({:creation_date => monitor.creation_date, :state => 'active'})
           doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => monitor.id, :data => options}
           Couchdb.create_doc doc,auth_session
         end
    end
    
  #returns a list of all active monitors managed by this scheduler
   def get_monitors(tag = nil)
      if (tag == nil)
        @scheduler.jobs
      else
        @scheduler.find_by_tag(tag)
      end
   end

   def status_report   
   end

 #stop an active running monitor 
 def stop_monitor(id)
   jobs = @scheduler.find_by_tag(id)
   jobs.each do |job| 
     job.unschedule
   end
   begin
     data = {:state => "stopped"}
     doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => data}   
     Couchdb.update_doc doc,Ragios::DatabaseAdmin.session
    rescue CouchdbException => e
      e.error
    end      
 end


 def restart(monitors)
  @monitors = monitors

  #read up the stats from database and add the stats values to the object   
  @monitors.each do |monitor|
     monitor.id = monitor.options[:_id]
     monitor.time_of_last_test = monitor.options[:time_of_last_test]   
     monitor.status = monitor.options[:status]
     if monitor.status == 'DOWN'
       monitor.was_down = TRUE   
     end
   end    
   start
 end
   
 def start  
  
   #schedule all the monitors to execute test_command() at every time_interval 
   @monitors.each do |monitor|
     @scheduler.every monitor.time_interval, :tags => monitor.id do          
       do_task(monitor)
     end 
    end  
 end

 def do_task(monitor)
    begin 
      monitor.time_of_last_test = Time.now.to_s(:long) 
      monitor.timestamp = Time.now.to_i 
      if monitor.test_command 
        monitor.status = 'UP'
        monitor.fixed if monitor.was_down 
        monitor.was_down = FALSE
      else
        monitor.status = 'DOWN'
             
        unless monitor.was_down 
          monitor.failed  
          monitor.notify    
          monitor.was_down = TRUE
        end 
      end
      #catch all exceptions
      rescue Exception
        #puts "ERROR: " +  $!.to_s  + " Created on: "+ Time.now.to_s(:long) 
        monitor.error_handler
      end
      Ragios::Logger.log(monitor)
          
      #update document with current state of this monitor        
      data = { 
         :describe_test_result => monitor.describe_test_result, 
         :time_of_last_test => monitor.time_of_last_test.to_s, 
         :last_test_result => monitor.test_result.to_s,  
         :status => monitor.status,
         :state => "active" }
     doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => monitor.id, :data => data}   
     Couchdb.update_doc doc,Ragios::DatabaseAdmin.session
  end #end of do_task
 end # end of class
 end
end





