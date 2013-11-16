module Ragios
  module Model
    class CouchdbMonitorModel
    
      def self.save(monitors_list) 
        monitors_list.each do |monitor|
          doc = {:database => monitors, :doc_id => monitor[:_id], :data => monitor}
          hash = Couchdb.create_doc doc,auth_session
        end
      end
    
      def self.delete(monitor_id)
        begin
          Couchdb.delete_doc({:database => monitors, :doc_id => monitor_id},auth_session)
        rescue CouchdbException => e
          not_found(monitor_id, e)
        end  
      end
      
      def self.find(monitor_id)
        begin
          monitor = Couchdb.view({:database => monitors, :doc_id => monitor_id},auth_session) 
        rescue CouchdbException => e
          not_found(monitor_id, e)
        end           
      end
      
      def self.update(monitor_id,options)
        begin
          doc = { :database => monitors, :doc_id => monitor_id, :data => options}   
          Couchdb.update_doc doc,auth_session
        rescue CouchdbException => e
          not_found(monitor_id, e)
        end          
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
        Couchdb.find_by_keys({:database => monitors, :keys => options}, auth_session) 
      end      
      
    private
      
      def self.not_found(monitor_id, e)
        raise Ragios::MonitorNotFound.new(error: "No monitor found"), "No monitor found with id = #{monitor_id}" if e.error == "not_found"
        raise e       
      end 
      
      def self.monitors
        Ragios::CouchdbAdmin.monitors
      end
      
      def self.auth_session
        Ragios::CouchdbAdmin.session
      end
      
    end
  end
end  
