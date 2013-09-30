module Ragios
  module Model
    class CouchdbModel
    
      def self.delete(id)
          Couchdb.delete_doc({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},Ragios::DatabaseAdmin.session)
      end
      
      def self.find(id)
          monitor = Couchdb.view({:database => Ragios::DatabaseAdmin.monitors, :doc_id => id},Ragios::DatabaseAdmin.session) 
     end
      
      def self.update(id,options)
        auth_session = Ragios::DatabaseAdmin.session
        doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => options}   
        Couchdb.update_doc doc,auth_session
      end
      
      def self.active_monitors
        view = {:database => Ragios::DatabaseAdmin.monitors,
                :design_doc => 'monitors',
                   :view => 'get_active_monitors',
                         :json_doc => $path_to_json + '/get_monitors.json'}
        Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
      end
      
      def self.all
        view = {:database => Ragios::DatabaseAdmin.monitors,
        						:design_doc => 'monitors',
         								:view => 'get_monitors',
          								:json_doc => $path_to_json + '/get_monitors.json'}

        Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
      end
      
      def self.where(options)
        Couchdb.find_by({:database => Ragios::DatabaseAdmin.monitors, options.keys[0] => options.values[0]},Ragios::DatabaseAdmin.session) 
      end
      
      def self.set_active(id)
        data = {:state => "active"}
        doc = { :database => Ragios::DatabaseAdmin.monitors, :doc_id => id, :data => data}   
        Couchdb.update_doc doc, Ragios::DatabaseAdmin.session
      end
      
      def self.stop
      end
      
      def stats(tag = nil)
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
      
      private 
      
      def self.auth_session
        Ragios::DatabaseAdmin.session
      end
    
    end
  end
end  

