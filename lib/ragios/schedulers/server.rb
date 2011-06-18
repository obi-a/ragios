module Ragios 
module Schedulers

class Server
    
    attr :monitors #list of long running monitors 

    def initialize(monitors)
         @monitors = monitors 
         Couchdb.create 'monitors'
         
         @monitors.each do |monitor|
           #puts monitor.options.inspect
           doc = {:database => 'monitors', :doc_id => UUIDTools::UUID.random_create.to_s, :data => monitor.options}
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
 end

 end # end of class
 end
end





