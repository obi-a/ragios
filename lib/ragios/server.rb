module Ragios 

#hides the messy details of the scheduler from users 
#provides an easy interface to start monitoring the system by calling Ragios::Server start monitors 
 class Server
   
    attr_accessor :ragios
    
    def initialize

    end

    def self.find_monitors(options) 
      Couchdb.find_by( :database => 'monitors', options.keys[0] => options.values[0])  
    end

    def self.find_stats(options)
      Couchdb.find_by( :database => 'stats', options.keys[0] => options.values[0])  
    end

   def self.update_status config
       #@ragios.update_status config
   end
    
    #returns a list of active monitors
    def self.get_monitors
       # @ragios.get_monitors
    end

    def self.restart monitors
       @ragios = Ragios::Schedulers::Server.new 
       @ragios.restart monitors 
    end

    def self.start monitors
        
     @ragios = Ragios::Schedulers::Server.new 
     @ragios.create monitors
     @ragios.start 
     #returns a list of active monitors
     #@ragios.get_monitors
    end
 end

end
