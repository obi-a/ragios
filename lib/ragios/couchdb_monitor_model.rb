module Ragios
  module Model
    class CouchdbMonitorModel
    
      def self.save(monitors_list) 
        begin
          Couchdb.create monitors,auth_session
        rescue CouchdbException 
        end
        monitors_list.each do |monitor|
          doc = {:database => monitors, :doc_id => monitor[:_id], :data => monitor}
          hash = Couchdb.create_doc doc,auth_session
        end
      end
    
      def self.delete(id)
        #should raise appropriate exception when monitor is not found
        Couchdb.delete_doc({:database => monitors, :doc_id => id},auth_session)
      end
      
      def self.find(id)
        #should raise appropriate exception when monitor id is not found
        monitor = Couchdb.view({:database => monitors, :doc_id => id},auth_session) 
     end
      
      def self.update(id,options)
        doc = { :database => monitors, :doc_id => id, :data => options}   
        Couchdb.update_doc doc,auth_session
      end
      
      def self.active_monitors
        view = {:database => monitors,
                :design_doc => 'monitors',
                   :view => 'get_active_monitors',
                         :json_doc => $path_to_json + '/get_monitors.json'}
        Couchdb.find_on_fly(view,auth_session)
      end
      
      def self.all
        view = {:database => monitors,
                    :design_doc => 'monitors',
                         :view => 'get_monitors',
                          :json_doc => $path_to_json + '/get_monitors.json'}

        Couchdb.find_on_fly(view,auth_session)
      end
      
      def self.where(options)
        Couchdb.find_by({:database => monitors, options.keys.first => options.values.first},auth_session) 
      end      
      
      private 
      
      def self.monitors
        Ragios::CouchdbAdmin.monitors
      end
      
      def self.auth_session
        Ragios::CouchdbAdmin.session
      end
    
    end
  end
end  
