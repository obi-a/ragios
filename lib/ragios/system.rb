module Ragios 

#hides the messy details of the scheduler from users 
#provides an easy interface to start monitoring the system by calling Ragios::System start monitoring 
 class System
   
    def initialize

    end

    def self.start (monitoring, trap_exit = TRUE)
        
     ragios = Ragios::Schedulers::RagiosScheduler.new monitoring
     ragios.init
     ragios.start trap_exit

    end
 end

end

