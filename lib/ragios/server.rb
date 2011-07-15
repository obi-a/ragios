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
    
    #returns a list of all monitors in the database
    def self.get_monitors
       #read off monitor values from database into a hash
     monitors = Couchdb.find(:database => "monitors", :design_doc => 'monitors', :view => 'get_monitors') 
      if(monitors.is_a?(Hash)) && (monitors.keys[0].to_s == "error")
        #when view doesn't exist find() returns {"error"=>"not_found", "reason"=>"missing"} 
        doc = { :database => 'monitors', :design_doc => 'monitors', :json_doc => $path_to_json + '/get_monitors.json' }
        Couchdb.create_design doc  
        monitors = Couchdb.find(:database => "monitors", :design_doc => 'monitors', :view => 'get_monitors') 
      end
      return monitors
    end

    def self.get_stats
      #read off stats values from database into a hash
      stats = Couchdb.find(:database => "stats", :design_doc => 'stats', :view => 'get_stats') 
      if(stats.is_a?(Hash)) && (stats.keys[0].to_s == "error")
        #when view doesn't exist find() returns {"error"=>"not_found", "reason"=>"missing"} 
        doc = { :database => 'stats', :design_doc => 'stats', :json_doc => $path_to_json + '/get_stats.json' }
        Couchdb.create_design doc  
        stats = Couchdb.find(:database => "stats", :design_doc => 'stats', :view => 'get_stats') 
      end
      return stats  
    end

    def self.restart monitors
       @ragios = Ragios::Schedulers::Server.new 
       @ragios.restart monitors 
    end

    def self.start monitors
        
     @ragios = Ragios::Schedulers::Server.new 
     @ragios.create monitors
     @ragios.start 
    end
 end

end
