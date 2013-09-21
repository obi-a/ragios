class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end

#TODO: Ragios::Server may need to should have an exception class 
#to allow clients like the RESTserver know exactly what a problem is with specific details.

module Ragios 

#hides the messy details of the scheduler from users 
#provides an easy interface to start monitoring the system by calling Ragios::Server start monitors 
 class Server
   
    attr_accessor :ragios
    
    def self.init
       @ragios = Ragios::Schedulers::Server.new 
    end

    def self.find_monitors(options) 
      Couchdb.find_by({:database => Ragios::DatabaseAdmin.monitors, options.keys[0] => options.values[0]},Ragios::DatabaseAdmin.session) 
    end

   def self.stop_monitor(id)
       @ragios.stop_monitor(id)
   end

   def self.restart_monitor(id)
      Ragios::Controller.restart_monitor(id)
   end


   def self.delete_monitor(id)
    begin 
     auth_session = Ragios::DatabaseAdmin.session
     monitor = Couchdb.view({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)    
     if(monitor["state"] == "active")
      stop_monitor(id)
     end
     
     Couchdb.delete_doc({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)

    rescue CouchdbException => e
       e.error
    end
   end

   def self.update_monitor(id, options)
      auth_session = Ragios::DatabaseAdmin.session
      doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => options}   
      Couchdb.update_doc doc,auth_session

     monitor = Couchdb.view( {:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},auth_session)
     
    if(monitor["state"] == "active")
      stop_monitor(id)
      restart_monitor(id)
    end
   end
  
    #returns a list of all active monitors in the database
    def self.get_active_monitors
       view = {:database => Ragios::DatabaseAdmin.monitors,
        :design_doc => 'monitors',
         :view => 'get_active_monitors',
          :json_doc => $path_to_json + '/get_monitors.json'}

       monitors = Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
       raise Ragios::MonitorNotFound.new(error: "No active monitor found"), "No active monitor found" if monitors.empty?
       return monitors
    end


  
   def self.get_monitor(id)
       doc = {:database => Ragios::DatabaseAdmin.monitors, :doc_id => id}
       Couchdb.view doc, Ragios::DatabaseAdmin.session
   end

   def self.get_all_monitors
      view = {:database => Ragios::DatabaseAdmin.monitors,
        :design_doc => 'monitors',
         :view => 'get_monitors',
          :json_doc => $path_to_json + '/get_monitors.json'}

         Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
   end

 

   def self.get_stats(tag = nil)

       auth_session = Ragios::DatabaseAdmin.session

       if(tag.nil?)
           view = {:database => Ragios::DatabaseAdmin.monitors,
        		:design_doc => 'get_stats',
         		:view => 'get_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
               Couchdb.find_on_fly(view,auth_session)  
       else
         view = {:database => Ragios::DatabaseAdmin.monitors,
        		:design_doc => 'get_stats',
         		:view => 'get_tag_and_mature_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
               Couchdb.find_on_fly(view, auth_session, key = tag)
      end
   end
    

  def self.get_monitors(tag = nil)
      @ragios.get_monitors(tag)
  end

   def self.get_monitors_frm_scheduler(tag = nil)
     if (tag.nil?)
        @ragios.get_monitors
      else
        @ragios.get_monitors(tag)
      end
   end
 
    def self.restart monitors
       @ragios.restart monitors 
    end

    def self.start monitors 
     @ragios.create monitors
     @ragios.start 
    end
 end

end
