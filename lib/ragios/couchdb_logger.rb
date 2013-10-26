module Ragios
  class CouchdbLogger
    def log(generic_monitor)
      data = {   
         :monitor_id => generic_monitor.id,
         :timestamp => generic_monitor.timestamp,
         :options => generic_monitor.options, 
         :time_of_test => generic_monitor.time_of_last_test,
         :test_result => generic_monitor.test_result, 
         :state => generic_monitor.state }
         
      data.merge!(:tag => generic_monitor.options[:tag]) if generic_monitor.options.has_key?(:tag)

      doc = { :database => activity_log, :doc_id => UUIDTools::UUID.random_create.to_s, :data => data}   
      Couchdb.create_doc doc,session  
    end
    
private 
    
    def activity_log
      Ragios::CouchdbAdmin.activity_log
    end
      
    def session
      Ragios::CouchdbAdmin.session
    end
  end
end
