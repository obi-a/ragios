module Ragios 

#hides the messy details of the scheduler from users 
#provides an easy interface to start monitoring the system by calling Ragios::System start monitoring 
 class System
   
    def initialize

    end

    def self.start monitoring
        
     ragios = Ragios::Schedulers::RagiosScheduler.new monitoring
     ragios.init
     ragios.start 

    end
 end

end

