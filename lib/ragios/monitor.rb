module Ragios 

#Translates the Ragios Domain Specific Language to monitoring objects

 class Monitor
   
    def initialize

    end

    def start monitoring
        

    end
 end

#Generic monitoring objects 
 class MonitoringHTTP < Ragios::Monitors::HTTP
   
   def initialize monitoring  
     
   end
 end

  
 class MonitoringURL < Ragios::Monitors::URL
   
   def initialize monitoring  
     
   end 
 end

 class MonitoringProcess < Ragios::Monitors::Process
   
   def initialize monitoring  
        
   end
 end

end

